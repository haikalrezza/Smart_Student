import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'webviewscreen.dart';

class UrlData {
  final String id;
  final String name;
  final String url;
  final IconData icon;

  UrlData(this.id, this.name, this.url, this.icon);
}

class WebViewApp extends StatefulWidget {
  @override
  _WebViewAppState createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<List<UrlData>> _stream;
  late String _userId;
  late IconData _selectedIcon;
  final List<IconData> _iconList = [
    Icons.book,
    Icons.web,
    Icons.language,
    Icons.lightbulb,
    Icons.code,
    Icons.attach_money,
    Icons.brush,
    Icons.computer,
    Icons.group,
    Icons.timelapse,
    // Add more icons as needed
  ];

  @override
  void initState() {
    super.initState();
    _selectedIcon = _iconList[0]; // Initialize with the first icon in the list
    _userId = _auth.currentUser!.uid;
    _stream = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('urls')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UrlData(
      doc.id,
      doc['name'],
      doc['url'],
      IconData(doc['icon'], fontFamily: 'MaterialIcons'),
    ))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade200,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.only(left: 16, top: 40),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 30,),
                Text(
                  'E-Learning Website',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: StreamBuilder<List<UrlData>>(
                stream: _stream,
                builder:
                    (BuildContext context, AsyncSnapshot<List<UrlData>> snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final List<UrlData> urls = snapshot.data ?? [];

                  if (urls.isEmpty) {
                    return Center(
                      child: Text('No URLs found.'),
                    );
                  }

                  return ListView.separated(
                    separatorBuilder: (context, index) => Divider(),
                    itemCount: urls.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(urls[index].icon), // Display the icon
                        title: Text(
                          urls[index].name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WebViewScreen(url: urls[index].url),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editUrl(urls[index]),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteUrl(urls[index]),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text('Add URL'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(hintText: 'Enter Name'),
                        ),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(hintText: 'Enter URL'),
                        ),
                        DropdownButton<IconData>(
                          value: _selectedIcon,
                          items: _iconList.map((IconData icon) {
                            return DropdownMenuItem<IconData>(
                              value: icon,
                              child: Icon(icon),
                            );
                          }).toList(),
                          onChanged: (IconData? value) {
                            setState(() {
                              _selectedIcon = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          final url = _urlController.text.trim();
                          if (name.isNotEmpty && url.isNotEmpty) {
                            final urlToAdd = _prependHttp(url);
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(_userId)
                                .collection('urls')
                                .add({
                              'name': name,
                              'url': urlToAdd,
                              'icon': _selectedIcon.codePoint, // Save the icon code point
                            });
                          }
                          _nameController.clear();
                          _urlController.clear();
                          Navigator.pop(context);
                        },
                        child: Text('Add'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  String _prependHttp(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }
    return url;
  }

  void _editUrl(UrlData urlData) {
    _nameController.text = urlData.name;
    _urlController.text = urlData.url;
    _selectedIcon = urlData.icon; // Set the selected icon

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit URL'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(hintText: 'Enter Name'),
                  ),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(hintText: 'Enter URL'),
                  ),
                  DropdownButton<IconData>(
                    value: _selectedIcon,
                    items: _iconList.map((IconData icon) {
                      return DropdownMenuItem<IconData>(
                        value: icon,
                        child: Icon(icon),
                      );
                    }).toList(),
                    onChanged: (IconData? value) {
                      setState(() {
                        _selectedIcon = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final url = _urlController.text.trim();
                    if (name.isNotEmpty && url.isNotEmpty) {
                      final urlToAdd = _prependHttp(url);
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_userId)
                          .collection('urls')
                          .doc(urlData.id)
                          .update({
                        'name': name,
                        'url': urlToAdd,
                        'icon': _selectedIcon.codePoint, // Save the icon code point
                      });
                    }
                    _nameController.clear();
                    _urlController.clear();
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteUrl(UrlData urlData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete URL'),
          content: Text('Are you sure you want to delete this URL?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(_userId)
                    .collection('urls')
                    .doc(urlData.id)
                    .delete();
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
