import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentVsAssessmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student vs Assessment'),
      ),
      body: ListView(
        children: [
          _buildHeaderSection(),
          _buildParticipationSection(),
          _buildDomainComparisonSection(),
          _buildAssessmentStatsSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Assessment Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2252A1),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Analyze student assessment performance and participation across different domains',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationSection() {
    // Mock data - replace with actual Firestore data in real implementation
    final int totalStudents = 5;
    final int studentsWithAssessments = 2;

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Participation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200, // تحديد ارتفاع ثابت للرسم البياني
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 60, // تقليل نصف القطر الداخلي
                  sections: [
                    PieChartSectionData(
                      value: studentsWithAssessments.toDouble(),
                      title: '${studentsWithAssessments}\nStudents',
                      color: Colors.blue,
                      radius: 60, // تقليل نصف القطر الخارجي
                      titleStyle: TextStyle(
                        fontSize: 12, // تصغير حجم الخط
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: (totalStudents - studentsWithAssessments).toDouble(),
                      title: '${totalStudents - studentsWithAssessments}\nStudents',
                      color: Colors.red,
                      radius: 60, // تقليل نصف القطر الخارجي
                      titleStyle: TextStyle(
                        fontSize: 12, // تصغير حجم الخط
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainComparisonSection() {
    // Mock data - replace with actual Firestore data in real implementation
    final Map<String, int> domainData = {
      'Database': 3,
      'Programming': 2,
      'DevOps': 1,
      'OS': 1
    };

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Domain Popularity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: domainData.values.reduce((a, b) => a > b ? a : b).toDouble(),
                  barGroups: List.generate(
                    domainData.length,
                        (index) {
                      final entry = domainData.entries.elementAt(index);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.toDouble(),
                            color: Colors.blue,
                            width: 22,
                          ),
                        ],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= domainData.length) return const Text('');
                          return Text(
                            domainData.keys.elementAt(value.toInt()),
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentStatsSection() {
    // Mock data - replace with actual Firestore data in real implementation
    final List<Map<String, dynamic>> assessmentStats = [
      {'name': 'Database Administrator', 'count': 1, 'avgScore': 50.0},
      {'name': 'C# Programming language', 'count': 2, 'avgScore': 55.0},
      {'name': 'DevOps & Cloud Computing', 'count': 1, 'avgScore': 85.0},
      {'name': 'Operating System', 'count': 1, 'avgScore': 4.1},
      {'name': 'Database Systems', 'count': 1, 'avgScore': 90.0},
    ];

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20, // تقليل المسافة بين الأعمدة
                columns: [
                  DataColumn(label: Text('Assessment', style: TextStyle(fontSize: 12))),
                  DataColumn(label: Text('Students', style: TextStyle(fontSize: 12))),
                  DataColumn(label:
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 60), // تحديد عرض عمود Avg Score
                    child: Text('Avg Score', style: TextStyle(fontSize: 12)),
                  ),
                  ),
                ],
                rows: assessmentStats.map((stat) {
                  return DataRow(
                    cells: [
                      DataCell(Text(stat['name'], style: TextStyle(fontSize: 12))),
                      DataCell(Text('${stat['count']}', style: TextStyle(fontSize: 12))),
                      DataCell(Text('${stat['avgScore']}%', style: TextStyle(fontSize: 12))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}