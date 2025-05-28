from flask import Flask, render_template, request, jsonify
import os
import json
import requests
import re
from datetime import datetime
from werkzeug.utils import secure_filename
from supabase import create_client, Client


# Server configuration
Server = '192.168.1.5'
Port = 5000

# Supabase configuration
SUPABASE_URL = 'https://xafztwdrytnggitdbioc.supabase.co'
SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhhZnp0d2RyeXRuZ2dpdGRiaW9jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ5MDU5ODgsImV4cCI6MjA2MDQ4MTk4OH0.Xn0b_ArBP2-sSyS9WBGHKlVUEMHMPt7FtCy5XBPtehk'
BUCKET_NAME = 'cv-pdf'

# Instantiate Flask app
app = Flask(__name__, template_folder='./templates')
app.secret_key = '1a2b5c4d7e'
app.config['UPLOAD_FOLDER'] = 'uploads'

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def get_next_submission_folder():
    """Generate sequential submission folder"""
    existing_folders = [d for d in os.listdir(app.config['UPLOAD_FOLDER']) 
                      if d.startswith("submission_")]
    next_num = len(existing_folders) + 1
    return os.path.join(app.config['UPLOAD_FOLDER'], f"submission_{next_num}")

def extract_ats_percentage(ai_response):
    """Extract percentage from AI response"""
    if isinstance(ai_response, dict):
        for key in ['ats_score', 'percentage', 'score', 'ats_percentage']:
            if key in ai_response:
                value = ai_response[key]
                if isinstance(value, str):
                    match = re.search(r'(\d+)%?', value)
                    return int(match.group(1)) if match else 0
                return int(value)
    
    text_response = str(ai_response)
    match = re.search(r'(\d{1,3})%', text_response)
    return int(match.group(1)) if match else 0

def upload_to_supabase(user_id: str, file_path: str, job_description: str, 
                      percentage: int, analysis_result: str) -> dict:
    """Upload CV to Supabase storage and save data to ats_data table"""
    try:
        # Generate unique filename for storage
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_name = secure_filename(os.path.basename(file_path))
        storage_path = f"user_uploads/{user_id}_{timestamp}_{file_name}"
        
        # Upload file to storage bucket
        with open(file_path, 'rb') as f:
            file_content = f.read()
        
        supabase.storage.from_(BUCKET_NAME).upload(
            path=storage_path,
            file=file_content,
            file_options={"content-type": "application/pdf"}
        )
        
        # Get public URL of the uploaded file
        file_url = supabase.storage.from_(BUCKET_NAME).get_public_url(storage_path)
        
        # Insert data into ats_data table with pdf_url
        response = supabase.table('ats_data').insert({
            "percentage_cv": percentage,
            "file_name": file_name,
            "job_description": job_description,
            "analysis_result": analysis_result,
            "user_id": user_id,
            "pdf_url": file_url  # Add the PDF URL here
        }).execute()
        
        if hasattr(response, 'error') and response.error:
            return {"success": False, "error": str(response.error)}
            
        return {
            "success": True,
            "file_url": file_url,
            "supabase_data": response.data
        }
        
    except Exception as e:
        return {"success": False, "error": str(e)}
    
@app.route('/')
def index():
    return render_template('index.html', title="ATS Scoring System")

@app.route('/submit', methods=['POST'])
def submit():
    # Get form data
    user_id = request.form.get('user_id')
    job_description = request.form.get('job_description')
    cv_file = request.files.get('cv_file')
    
    # Validate inputs
    if not all([user_id, job_description, cv_file]):
        return jsonify({"error": "Missing required fields"}), 400
    
    try:
        # Create submission folder
        submission_folder = get_next_submission_folder()
        os.makedirs(submission_folder, exist_ok=True)
        
        # Save CV locally
        cv_filename = secure_filename(cv_file.filename)
        cv_path = os.path.join(submission_folder, cv_filename)
        cv_file.save(cv_path)
        
        # Save job description
        with open(os.path.join(submission_folder, "job_description.txt"), 'w') as f:
            f.write(job_description)
        
        # Process with AI model
        ai_response = send_to_ai_model(job_description, cv_path)
        ats_percentage = extract_ats_percentage(ai_response)
        processed_response = process_ai_response(ai_response)
        
        # Upload to Supabase
        supabase_result = upload_to_supabase(
            user_id=user_id,
            file_path=cv_path,
            job_description=job_description,
            percentage=ats_percentage,
            analysis_result=processed_response
        )
        
        # Save local metadata
        metadata = {
            "user_id": user_id,
            "job_description": job_description,
            "cv_filename": cv_filename,
            "ats_percentage": ats_percentage,
            "supabase_result": supabase_result,
            "timestamp": datetime.now().isoformat()
        }
        
        with open(os.path.join(submission_folder, "metadata.json"), 'w') as f:
            json.dump(metadata, f, indent=2)
        
        return jsonify({
            "success": True,
            "percentage": ats_percentage,
            "ai_response": processed_response,
            "supabase": supabase_result,
            "local_path": submission_folder
        })
        
    except Exception as e:
        return jsonify({
            "error": f"Processing failed: {str(e)}",
            "success": False
        }), 500

def send_to_ai_model(job_description: str, cv_path: str) -> dict:
    """Send data to AI model endpoint"""
    try:
        with open(cv_path, 'rb') as f:
            files = {'file': f}
            data = {'input_text': job_description}
            response = requests.post(
                "http://localhost:8501/process",
                files=files,
                data=data,
                timeout=30
            )
        return response.json() if response.status_code == 200 else {"error": f"AI model error: {response.status_code}"}
    except requests.exceptions.RequestException as e:
        return {"error": f"AI model connection failed: {str(e)}"}

def process_ai_response(ai_response: dict) -> str:
    """Format AI response for client"""
    if isinstance(ai_response, dict) and "error" in ai_response:
        return ai_response["error"]
    
    response_text = ai_response.get("result", str(ai_response))
    formatted = response_text.replace(". ", ".\n")
    return re.sub(r'\*\*(.*?)\*\*', r'__\1__', formatted)

if __name__ == '__main__':
    app.run(host=Server, port=Port, debug=True)