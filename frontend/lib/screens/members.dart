import '../services/demo_catalog.dart';
import 'package:flutter/material.dart';

class Members extends StatefulWidget {
  final DemoCatalog catalog;
  const Members(this.catalog, {super.key});
  @override
  State<Members> createState() => _MembersState();
}

class _MembersState extends State<Members> {

  // 1. MEMBER DATA
  List<Map<String, String>> get members => widget.catalog.members;
  String searchText = '';

  // 2. SEARCH MEMBERS
  List<Map<String, String>> get visibleMembers {
    return members.where((member) {
      return member['name']!
          .toLowerCase()
          .contains(searchText.toLowerCase());
    }).toList();
  }

  // 3. MAIN SCREEN
  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> shown = visibleMembers;

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 3.1 Page title
          Text(
            'Members Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          // 3.2 Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search members by name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 20),

          // 3.3 Add Member button
          ElevatedButton.icon(
            onPressed: () => openMemberForm(),
            icon: Icon(Icons.add),
            label: Text('Add Member'),
          ),

          SizedBox(height: 20),

          // 3.4 Members list title
          Text(
            'Members List',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 10),

          // 3.5 Display members
          Expanded(
            child: shown.isEmpty
                ? Center(child: Text('No members available'))
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      return memberCard(shown[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 4. MEMBER CARD
  Widget memberCard(Map<String, String> member) {
    return Card(
      child: ListTile(

        // 4.1 Member details
        title: Text(member['name'] ?? ''),
        subtitle: Text(member['email'] ?? ''),

        // 4.2 Edit and Delete buttons
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            // 4.2.1 Edit
            IconButton(
              icon: Icon(Icons.edit),
              tooltip: 'Edit Member',
              onPressed: () {
                openMemberForm(existing: member);
              },
            ),

            // 4.2.2 Delete
            IconButton(
              icon: Icon(Icons.delete),
              tooltip: 'Delete Member',
              onPressed: () {
                if (widget.catalog.bookings.any((b) => b.slot.memberId.toString() == member['id'].toString())) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This member has booking history and cannot be deleted.')));
                      return;
                    }
                    setState(() {
                  members.remove(member);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // 5. ADD AND EDIT MEMBER FORM
  Future<void> openMemberForm({
    Map<String, String>? existing,
  }) async {

    // 5.1 Text controllers
    TextEditingController name = TextEditingController(
      text: existing?['name'] ?? '',
    );

    TextEditingController email = TextEditingController(
      text: existing?['email'] ?? '',
    );

    // 5.2 Open popup
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Add Member' : 'Edit Member',
          ),

          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // 5.3 Member name
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'Member Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 15),

                // 5.4 Member email
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [

            // 5.5 Cancel button
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text('Cancel'),
            ),

            // 5.6 Save button
            ElevatedButton(
              onPressed: () {

                // 5.6.1 Check entered information
                String newName = name.text.trim();
                String newEmail = email.text.trim();

                if (newName.isEmpty || newEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in all fields'),
                    ),
                  );
                  return;
                }

                // 5.6.2 Add or update member
                setState(() {
                  if (existing == null) {
                    members.add({
                      'id': (widget.catalog.nextMemberId++).toString(),
                      'name': newName,
                      'email': newEmail,
                    });
                  } else {
                    existing['name'] = newName;
                    existing['email'] = newEmail;
                  }
                });

                // 5.6.3 Close popup
                Navigator.pop(dialogContext);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    // 5.7 Clean up controllers
    name.dispose();
    email.dispose();
  }
}