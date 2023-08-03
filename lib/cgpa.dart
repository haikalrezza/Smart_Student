import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GPAInputScreen extends StatefulWidget {
  @override
  _GPAInputScreenState createState() => _GPAInputScreenState();
}

class _GPAInputScreenState extends State<GPAInputScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedSemester = 'Semester 1';
  List<String> _semesterOptions = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'];

  List<Subject> _subjects = [];
  ValueNotifier<double> _gpaNotifier = ValueNotifier<double>(0.0);

  double _totalCredits = 0.0;

  double _cgpa = 0.0;
  double _cumulativeCredits = 0.0;

  void _addSubject() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? subjectName;
        double? subjectCredit;
        String? subjectGrade;

        return AlertDialog(
          title: Text('Add Subject'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  onChanged: (value) {
                    subjectName = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                  ),
                ),
                TextFormField(
                  onChanged: (value) {
                    subjectCredit = double.tryParse(value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Credit',
                  ),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: subjectGrade,
                  onChanged: (value) {
                    subjectGrade = value;
                  },
                  items: [
                    DropdownMenuItem<String>(
                      value: 'A',
                      child: Text('A'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'A-',
                      child: Text('A-'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'B+',
                      child: Text('B+'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'B',
                      child: Text('B'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'B-',
                      child: Text('B-'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'C+',
                      child: Text('C+'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'C',
                      child: Text('C'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'C-',
                      child: Text('C-'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'D+',
                      child: Text('D+'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'D',
                      child: Text('D'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'E',
                      child: Text('E'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Grade',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _saveSubject(
                  subjectName!,
                  subjectCredit!,
                  subjectGrade!,
                );
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _saveSubject(String name, double credit, String grade) async {
    final User? user = _auth.currentUser;
    final userId = user!.uid;
    final DocumentReference semesterDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cgpa')
        .doc(_selectedSemester);



    final subjectData = {
      'name': name,
      'credit': credit,
      'grade': grade,
    };

    await semesterDocRef.collection('subjects').add(subjectData);
    

    _calculateGPA();



    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subject added successfully!')),
    );
    _fetchSubjects();

    await semesterDocRef.set({'Semester': _selectedSemester}, SetOptions(merge: true));
    // Update the total credits and GPA in the gpacredit collection
    await semesterDocRef.collection('gpacredit').doc('credit').set({'totalCredits': _totalCredits });
    await semesterDocRef.collection('gpacredit').doc('gpa').set({'value': _gpaNotifier.value});

    _fetchGPAAndCredit();
  }

  void _deleteSubject(String subjectId) async {
    final User? user = _auth.currentUser;
    final userId = user!.uid;
    final DocumentReference semesterDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cgpa')
        .doc(_selectedSemester);

    final deletedSubjectDoc = await semesterDocRef.collection('subjects').doc(subjectId).get();
    final double deletedSubjectCredit = deletedSubjectDoc.data()?['credit'] ?? 0.0;

    await semesterDocRef.collection('subjects').doc(subjectId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subject deleted successfully!')),
    );

    _fetchSubjects();


    // Update totalCredits by subtracting the credit of the deleted subject


    // Update totalCredits in Firestore
    await semesterDocRef.collection('gpacredit').doc('credit').set({'totalCredits': _totalCredits-deletedSubjectCredit});
    await semesterDocRef.collection('gpacredit').doc('gpa').set({'value': _gpaNotifier.value});

    _fetchGPAAndCredit();
  }


  void _fetchSubjects() async {
    final User? user = _auth.currentUser;
    final userId = user!.uid;
    final DocumentReference semesterDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cgpa')
        .doc(_selectedSemester);

    final subjectSnapshot = await semesterDocRef.collection('subjects').get();


    setState(() {
      _subjects = subjectSnapshot.docs
          .map((doc) => Subject(
        id: doc.id,
        name: doc.data()['name'],
        credit: doc.data()['credit'],
        grade: doc.data()['grade'],
      ))
          .toList();

      _calculateGPA(); // Calculate GPA when subjects are fetched
    });
    _fetchGPAAndCredit();


  }



  void _calculateGPA() {
    double totalCreditPoints = 0.0;
    double totalCredits = 0.0;

    for (var subject in _subjects) {
      double credit = subject.credit ?? 0.0;
      String grade = subject.grade ?? '';

      if (grade.isNotEmpty) {
        double gradePoint = _calculateGradePoint(grade);
        totalCreditPoints += credit * gradePoint;
        totalCredits += credit;
      }
    }

    double gpa = 0.0;
    if (totalCredits > 0) {
      gpa = totalCreditPoints / totalCredits;
    }

    _totalCredits = totalCredits;
    _gpaNotifier.value = gpa;
  }

  double _calculateGradePoint(String grade) {
    switch (grade) {
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D+':
        return 1.3;
      case 'D':
        return 1.0;
      case 'E':
        return 0.0;
      default:
        return 0.0;
    }
  }

  Future<void> _fetchGPAAndCredit() async {
    final User? user = _auth.currentUser;
    final userId = user!.uid;
    final CollectionReference userCollection = _firestore.collection('users');
    final QuerySnapshot semestersSnapshot = await userCollection
        .doc(userId)
        .collection('cgpa')
        .get();


    // final int numberOfDocuments = semestersSnapshot.size;
    // print('Number of documents inside cgpa collection: $numberOfDocuments');

    double totalGPA = 0.0;
    double totalCumulativeCredits = 0.0;

    for (final semester in semestersSnapshot.docs) {
      final semesterDocRef = userCollection
          .doc(userId)
          .collection('cgpa')
          .doc(semester.id);

      final gpaSnapshot = await semesterDocRef
          .collection('gpacredit')
          .doc('gpa')
          .get();

      final creditSnapshot = await semesterDocRef
          .collection('gpacredit')
          .doc('credit')
          .get();

      final gpa = gpaSnapshot.data()?['value'] ?? 0.0;
      final credit = creditSnapshot.data()?['totalCredits'] ?? 0.0;

      totalGPA += gpa;
      totalCumulativeCredits += credit;

    }

    setState(() {
      _cgpa = totalGPA / semestersSnapshot.size;
      _cumulativeCredits = totalCumulativeCredits;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchSubjects();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30,),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 16.0),
                Text(
                  'GPA Calculator',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        Text(
          'CGPA: ${_cgpa.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 16.0),
            Text(
              'Credit: $_cumulativeCredits',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedSemester,
              onChanged: (value) {
                setState(() {
                  _selectedSemester = value!;
                  _fetchSubjects();
                });
              },
              items: _semesterOptions
                  .map((semester) => DropdownMenuItem<String>(
                value: semester,
                child: Text(semester),
              ))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Select Semester',
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Subjects',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _subjects.length,
                itemBuilder: (BuildContext context, int index) {
                  final subject = _subjects[index];
                  return ListTile(
                    title: Text(
                      subject.name ?? '',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Credit: ${subject.credit ?? ''}, Grade: ${subject.grade ?? ''}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _deleteSubject(subject.id!);
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'GPA: ${_gpaNotifier.value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total Credits: $_totalCredits',
              style: TextStyle(
                fontSize: 24.0,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        child: Icon(Icons.add),
      ),
    );

  }
}

class Subject {
  final String? id;
  final String? name;
  final double? credit;
  final String? grade;

  Subject({this.id, this.name, this.credit, this.grade});
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPA Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GPAInputScreen(),
    );
  }
}
