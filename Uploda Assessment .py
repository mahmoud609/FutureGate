import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import json

# Initialize Firebase connection
cred = credentials.Certificate(r"C:\Users\HP\Downloads\futuregate-2b24b-firebase-adminsdk-fbsvc-c3b243a7aa.json")  # Firebase admin SDK credentials
firebase_admin.initialize_app(cred)
db = firestore.client()

def insert_quizzes(data):
    """Processes quiz data and inserts into Firestore"""
    for quiz in data:
        # Validate required fields
        if "title" not in quiz or "questions" not in quiz:
            print(f"⚠️ Skipping quiz with missing data: {quiz.get('title', 'Untitled')}")
            continue

        quiz_title = quiz["title"].strip()
        if not quiz_title:
            print("⚠️ Skipping quiz with empty title!")
            continue

        print(f"📂 Adding quiz: {quiz_title}")
        
        # Create quiz document in Assessment collection
        quiz_ref = db.collection("Assessment").document()  # Main collection for quizzes
        quiz_ref.set({"title": quiz_title})

        # Add questions to subcollection
        for question in quiz["questions"]:
            if not all(key in question for key in ["question", "options", "answer"]):
                print(f"   ⚠️ Skipping malformed question: {question}")
                continue
            
            quiz_ref.collection("Questions").add(question)  # Changed from Assessment to Questions
            print(f"   ➕ Added question: {question['question'][:30]}...")

    print("✅ Data inserted successfully!")

def submit_quiz(quiz_id, user_id, user_answers):
    """Calculates and stores quiz results"""
    try:
        # 1. Fetch correct answers from Firestore
        questions_ref = db.collection("Assessment").document(quiz_id).collection("Questions")  # Questions subcollection
        correct_answers = {q.id: q.to_dict()["answer"] for q in questions_ref.stream()}
        
        # 2. Calculate score
        score = 0
        for q_id, user_answer in user_answers.items():
            if user_answer == correct_answers.get(q_id):
                score += 1
        
        # 3. Store results
        db.collection("Results").add({
            "quiz_id": quiz_id,
            "user_id": user_id,
            "score": score,
            "total": len(correct_answers),
            "timestamp": datetime.now()
        })
        
        return {"score": score, "total": len(correct_answers)}
    
    except Exception as e:
        print(f"❌ Error calculating results: {e}")
        return None

if __name__ == "__main__":
    try:
        # 1. Insert quiz data
        with open(r"C:\Users\HP\Downloads\ass[1].json", "r", encoding="utf-8") as f:  # Quiz data JSON file
            data = json.load(f)
        insert_quizzes(data)
        
        # 2. Simulate quiz submission (replace with actual data)
        quiz_id = "abc123"  # Should be real quiz ID
        user_id = "user456"
        user_answers = {
            "q1_id": "User answer 1",
            "q2_id": "User answer 2"
        }
        
        result = submit_quiz(quiz_id, user_id, user_answers)
        if result:
            print(f"Score: {result['score']}/{result['total']}")
        
    except FileNotFoundError:
        print("❌ JSON file not found!")
    except json.JSONDecodeError:
        print("❌ Invalid JSON file!")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
