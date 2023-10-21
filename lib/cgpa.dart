import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bits.dart';
import 'bitz.dart';

class GPAInputScreen extends StatefulWidget {
  @override
  _GPAInputScreenState createState() => _GPAInputScreenState();
}

class _GPAInputScreenState extends State<GPAInputScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSemesterDone = false; // New variable to track semester status
  
  

  String _selectedSemester = 'Year One : Semester 1';
  List<String> _semesterOptions = [
    'Year One : Semester 1',
    'Year One : Semester 2',
    'Year Two : Semester 1',
    'Year Two : Semester 2',
    'Year Three : Semester 1',
    'Year Three : Semester 2',
    'Year Three : Special Semester',
    'Year Four : Semester 1',
  ];

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

  Future<void> _predefined() async {
    final List<String> allSemesters = [
      'Year One : Semester 1',
      'Year One : Semester 2',
      'Year Two : Semester 1',
      'Year Two : Semester 2',
      'Year Three : Semester 1',
      'Year Three : Semester 2',
      'Year Three : Special Semester',
      'Year Four : Semester 1',
    ];




      final User? user = _auth.currentUser;
      final userId = user!.uid;
      final List<Future<void>> addSubjectTasks = [];

      for (final semester in allSemesters) {
        final DocumentReference semesterDocRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('cgpa')
            .doc(semester);

        final subjectsForSemester = bitz[semester];
        if (subjectsForSemester != null) {
          for (final subjectData in subjectsForSemester) {
            addSubjectTasks.add(semesterDocRef.collection('subjects').add(subjectData));
          }

      }

      await Future.wait(addSubjectTasks);
      print('Predefined subjects added for all semesters');
    }
    _calculateGPA();







    _fetchGPAAndCredit();

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

  Future<void> _fetchIsSemesterDone() async {
    final User? user = _auth.currentUser;
    final userId = user!.uid;
    final DocumentReference semesterDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cgpa')
        .doc(_selectedSemester);

    // Fetch the semester status
    final semesterSnapshot = await semesterDocRef.get();

    final data = semesterSnapshot.data() as Map<String, dynamic>?;

    if (data != null) {
      setState(() {
        _isSemesterDone = data['_isSemesterDone'] ?? false;
      });

      // Update the checkbox state based on '_isSemesterDone'
      _updateSemesterDoneStatus(_isSemesterDone);
    }
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
    _fetchIsSemesterDone();


  }

  void _updateSubjectGrade(Subject subject, String updatedGrade) async {
    final User? user = _auth.currentUser;
    final userId = user!.uid;
    final DocumentReference semesterDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cgpa')
        .doc(_selectedSemester);

    final subjectDocRef = semesterDocRef.collection('subjects').doc(subject.id);
    await subjectDocRef.update({'grade': updatedGrade});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Grade updated successfully!')),
    );

    // After updating the grade, refresh the subjects list
    _fetchSubjects();
    await semesterDocRef.collection('gpacredit').doc('credit').set({'totalCredits': _totalCredits });
    await semesterDocRef.collection('gpacredit').doc('gpa').set({'value': _gpaNotifier.value});

    _fetchGPAAndCredit();
  }


  void _editSubjectGrade(Subject subject) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? updatedGrade = subject.grade;

        return AlertDialog(
          title: Text('Edit Grade'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: updatedGrade ?? 'A', // Set 'A' as the default value
                  onChanged: (value) {
                    updatedGrade = value;
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
                    DropdownMenuItem<String>(
                      value: 'N/A',
                      child: Text('N/A'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Grade',
                  ),
                )

              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _updateSubjectGrade(subject, updatedGrade!);
                Navigator.pop(context);
              },
              child: Text('Save'),
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
  void _updateSemesterDoneStatus(bool isDone) async {
    final User? user = _auth.currentUser;
    final userId = user!.uid;
    final DocumentReference semesterDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cgpa')
        .doc(_selectedSemester);

    await semesterDocRef.set({'_isSemesterDone': isDone}, SetOptions(merge: true));
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

    int numberOfSemestersDone = 0; // Initialize the counter

    for (final semester in semestersSnapshot.docs) {
      final semesterDocRef = userCollection
          .doc(userId)
          .collection('cgpa')
          .doc(semester.id);

      // Check if the semester is marked as done
      final isSemesterDone =
          (semester.data() as Map<String, dynamic>?)?['_isSemesterDone'] ?? false;

      if (isSemesterDone) {
        numberOfSemestersDone++; // Increment the counter for done semesters
      }
    }

    // Calculate the year of study based on the number of done semesters (1 year = 2 semesters)
    int yearOfStudy = (numberOfSemestersDone / 2).ceil();

    // Update the "Year of Study" under the user's profile
    await userCollection.doc(userId).collection('userprofile').doc('profile').update({'yearOfStudy': yearOfStudy.toString()});

    double totalGPA = 0.0;
    double totalCumulativeCredits = 0.0;

    for (final semester in semestersSnapshot.docs) {
      final semesterDocRef = userCollection
          .doc(userId)
          .collection('cgpa')
          .doc(semester.id);

      // Check if the semester is marked as done
      final isSemesterDone =
          (semester.data() as Map<String, dynamic>?)?['_isSemesterDone'] ?? false;

      if (isSemesterDone) {
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
    }

    print('totalgpa' + totalGPA.toString() + 'numsemdone' + numberOfSemestersDone.toString());
    setState(() {
      _cgpa = totalGPA / numberOfSemestersDone; // Total GPA for done semesters
      _cumulativeCredits = totalCumulativeCredits; // Cumulative credits for done semesters
      
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
                  'CGPA Tracker',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
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
              ],
            ),
                SizedBox(width: 200,),
                FloatingActionButton(onPressed: _fetchSubjects, child: Icon(Icons.refresh), backgroundColor: Colors.green[100],mini: true,),
          ],
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
              child: _subjects.isEmpty
                  ? Center(
                child: Text(
                  'Please select your course in edit profile section first',
                  style: TextStyle(fontSize: 14.0),
                ),
              )
                  : ListView.builder(
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
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _editSubjectGrade(subject);
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
            Row(
              children: [
                Text('Finished Semester'),
                Checkbox(
                  value: _isSemesterDone,
                  onChanged: (newValue) {
                    setState(() {
                      _isSemesterDone = newValue!;
                      _updateSemesterDoneStatus(newValue!);
                    });
                  },
                ),
              ],
            ),
         ],
        ),
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
