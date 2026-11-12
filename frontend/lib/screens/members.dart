import 'package:flutter/material.dart';

import '../services/demo_catalog.dart';
import '../services/member_api.dart';

class Members extends StatefulWidget {
  final DemoCatalog catalog;

  const Members(this.catalog, {super.key});

  @override
  State<Members> createState() => _MembersState();
}

class _MembersState extends State<Members> {
  // 1. MEMBER DATA
  final MemberApi memberApi = MemberApi();

  List<Map<String, String>> members = [];
  String searchText = '';
  bool isLoading = true;
  String? errorMessage;

  // 2. LOAD MEMBERS FROM BACKEND
  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await memberApi.getMembers();

      if (!mounted) return;

      setState(() {
        members = data.map<Map<String, String>>((member) {
          return {
            'id': member['id'].toString(),
            'name': member['fullName']?.toString() ?? '',
            'email': member['email']?.toString() ?? '',
          };
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // 3. SEARCH MEMBERS
  List<Map<String, String>> get visibleMembers {
    return members.where((member) {
      return (member['name'] ?? '').toLowerCase().contains(
        searchText.toLowerCase(),
      );
    }).toList();
  }

  // 4. MAIN SCREEN
  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> shown = visibleMembers;

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4.1 PAGE TITLE
          Text(
            'Members Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20),

          // 4.2 SEARCH BAR
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

          // 4.3 ADD MEMBER BUTTON
          ElevatedButton.icon(
            onPressed: () {
              openMemberForm();
            },
            icon: Icon(Icons.add),
            label: Text('Add Member'),
          ),

          SizedBox(height: 20),

          // 4.4 MEMBERS LIST TITLE
          Text(
            'Members List',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10),

          // 4.5 DISPLAY MEMBERS
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load members'),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: loadMembers,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : shown.isEmpty
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

  // 5. MEMBER CARD
  Widget memberCard(Map<String, String> member) {
    return Card(
      child: ListTile(
        // 5.1 MEMBER DETAILS
        title: Text(member['name'] ?? ''),
        subtitle: Text(member['email'] ?? ''),

        // 5.2 EDIT AND DELETE BUTTONS
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 5.2.1 EDIT MEMBER
            IconButton(
              icon: Icon(Icons.edit),
              tooltip: 'Edit Member',
              onPressed: () {
                openMemberForm(existing: member);
              },
            ),

            // 5.2.2 DELETE MEMBER
            IconButton(
              icon: Icon(Icons.delete),
              tooltip: 'Delete Member',
              onPressed: () async {
                await deleteMember(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 6. DELETE MEMBER
  Future<void> deleteMember(Map<String, String> member) async {
    // 6.1 CHECK LOCAL BOOKING HISTORY
    bool hasBooking = widget.catalog.bookings.any(
      (b) => b.slot.memberId.toString() == member['id'],
    );

    if (hasBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This member has booking history and cannot be deleted.',
          ),
        ),
      );
      return;
    }

    // 6.2 DELETE FROM BACKEND
    try {
      await memberApi.deleteMember(member['id']!);

      if (!mounted) return;

      await loadMembers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete member')));
    }
  }

  // 7. ADD AND EDIT MEMBER FORM
  Future<void> openMemberForm({Map<String, String>? existing}) async {
    // 7.1 TEXT CONTROLLERS
    TextEditingController name = TextEditingController(
      text: existing?['name'] ?? '',
    );

    TextEditingController email = TextEditingController(
      text: existing?['email'] ?? '',
    );

    // 7.2 OPEN POPUP
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Member' : 'Edit Member'),

          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 7.3 MEMBER NAME
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'Member Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 15),

                // 7.4 MEMBER EMAIL
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
            // 7.5 CANCEL BUTTON
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text('Cancel'),
            ),

            // 7.6 SAVE BUTTON
            ElevatedButton(
              onPressed: () async {
                // 7.6.1 CHECK ENTERED INFORMATION
                String newName = name.text.trim();
                String newEmail = email.text.trim();

                if (newName.isEmpty || newEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                // 7.6.2 SAVE TO BACKEND
                try {
                  if (existing == null) {
                    await memberApi.addMember(newName, newEmail);
                  } else {
                    await memberApi.updateMember(
                      existing['id']!,
                      newName,
                      newEmail,
                    );
                  }

                  if (!mounted || !dialogContext.mounted) return;

                  // 7.6.3 CLOSE POPUP
                  Navigator.pop(dialogContext);

                  // 7.6.4 REFRESH MEMBERS
                  await loadMembers();
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save member')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    // 7.7 CLEAN UP CONTROLLERS
    name.dispose();
    email.dispose();
  }
}
