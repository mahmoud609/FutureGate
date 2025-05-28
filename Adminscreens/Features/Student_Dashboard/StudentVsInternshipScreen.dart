import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';

class StudentVsInternshipScreen extends StatefulWidget {
  static const String routeName = '/StudentVsInternshipScreen';

  @override
  _StudentVsInternshipScreenState createState() => _StudentVsInternshipScreenState();
}

class _StudentVsInternshipScreenState extends State<StudentVsInternshipScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  // Data containers
  int totalRegisteredStudents = 0;
  int totalAppliedStudents = 0;
  Map<String, int> fieldDistribution = {};
  Map<String, int> cvMethodDistribution = {};
  List<MonthlyApplicationData> monthlyApplications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // In a real implementation, we would fetch actual data from Firebase
      // For demo purposes, we're using mock data based on the information provided

      // Simulate network delay
      await Future.delayed(Duration(seconds: 1));

      // Get registered students count (from users collection)
      totalRegisteredStudents = 8; // Mock data - would be fetched from Firebase

      // Get applied students count (from Student_Applicant collection)
      totalAppliedStudents = 5; // Mock data - would be fetched from Firebase

      // Get field distribution
      fieldDistribution = {
        'Business Information System': 6,
        'Information System': 2,
        'Computer Science': 0,
      };

      // Get CV method distribution
      cvMethodDistribution = {
        'Built CV': 3,
        'Uploaded CV': 2,
      };

      // Get monthly application trend
      monthlyApplications = [
        MonthlyApplicationData('Jan', 0),
        MonthlyApplicationData('Feb', 1),
        MonthlyApplicationData('Mar', 2),
        MonthlyApplicationData('Apr', 2),
        MonthlyApplicationData('May', 5),
      ];

      // Update UI
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Student vs Internship',
          style: TextStyle(
            color: Color(0xFF2252A1),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF2252A1)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoading = true;
          });
          await _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Registration vs Application Status'),
              _buildRegistrationVsApplicationChart(),

              const SizedBox(height: 24),
              _buildSectionTitle('Student Field Distribution'),
              _buildFieldDistributionChart(),

              const SizedBox(height: 24),
              _buildSectionTitle('CV Submission Methods'),
              _buildCvMethodsChart(),

              const SizedBox(height: 24),
              _buildSectionTitle('Monthly Application Trend'),
              _buildMonthlyTrendChart(),

              const SizedBox(height: 24),
              _buildKeyMetricsCards(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2252A1),
        ),
      ),
    );
  }

  Widget _buildRegistrationVsApplicationChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: totalRegisteredStudents * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        if (value == 0) {
                          text = 'Registered';
                        } else if (value == 1) {
                          text = 'Applied';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: totalRegisteredStudents.toDouble(),
                        color: Color(0xFF2252A1),
                        width: 60,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: totalAppliedStudents.toDouble(),
                        color: Colors.blue[300],
                        width: 60,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Color(0xFF2252A1), 'Registered Students'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.blue[300]!, 'Applied Students'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldDistributionChart() {
    final List<PieChartSectionData> pieChartSections = [];
    final colors = [
      Color(0xFF2252A1),
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    int index = 0;
    fieldDistribution.forEach((field, count) {
      if (count > 0) { // Only add non-zero values
        pieChartSections.add(
          PieChartSectionData(
            value: count.toDouble(),
            title: '$count',
            color: colors[index % colors.length],
            radius: 100,
            titleStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      }
      index++;
    });

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: pieChartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(
              fieldDistribution.length,
                  (index) {
                final entry = fieldDistribution.entries.elementAt(index);
                return _buildLegendItem(
                  colors[index % colors.length],
                  '${entry.key} (${entry.value})',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCvMethodsChart() {
    final List<PieChartSectionData> pieChartSections = [];
    final colors = [
      Colors.orange,
      Colors.purple,
    ];

    int index = 0;
    cvMethodDistribution.forEach((method, count) {
      pieChartSections.add(
        PieChartSectionData(
          value: count.toDouble(),
          title: '$count',
          color: colors[index % colors.length],
          radius: 100,
          titleStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
      index++;
    });

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: pieChartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(colors[0], 'Built CV (${cvMethodDistribution['Built CV']})'),
              const SizedBox(width: 16),
              _buildLegendItem(colors[1], 'Uploaded CV (${cvMethodDistribution['Uploaded CV']})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    final spots = monthlyApplications
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.applications.toDouble()))
        .toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < monthlyApplications.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        monthlyApplications[value.toInt()].month,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          minX: 0,
          maxX: (monthlyApplications.length - 1).toDouble(),
          maxY: monthlyApplications.map((e) => e.applications).reduce((a, b) => a > b ? a : b) * 1.2,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Color(0xFF2252A1),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Color(0xFF2252A1),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Color(0xFF2252A1).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCards() {
    final applicationRate = (totalAppliedStudents / totalRegisteredStudents * 100).round();

    String mostPopularField = "";
    int highestCount = 0;
    fieldDistribution.forEach((field, count) {
      if (count > highestCount) {
        highestCount = count;
        mostPopularField = field;
      }
    });

    String preferredCvMethod = "";
    int highestCvCount = 0;
    cvMethodDistribution.forEach((method, count) {
      if (count > highestCvCount) {
        highestCvCount = count;
        preferredCvMethod = method;
      }
    });

    final totalCvs = cvMethodDistribution.values.reduce((a, b) => a + b);
    final preferredCvPercentage = (highestCvCount / totalCvs * 100).round();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Application Rate',
                value: '$applicationRate%',
                description: 'of registered students have applied',
                icon: Iconsax.percentage_square,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Most Popular Field',
                value: mostPopularField,
                description: 'with $highestCount students',
                icon: Iconsax.book,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Preferred CV Method',
                value: preferredCvMethod,
                description: '$preferredCvPercentage% of applications',
                icon: Iconsax.document,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class MonthlyApplicationData {
  final String month;
  final int applications;

  MonthlyApplicationData(this.month, this.applications);
}