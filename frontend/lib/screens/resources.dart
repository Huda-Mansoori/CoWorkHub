import '../services/demo_catalog.dart';
import 'package:flutter/material.dart';

class Resources extends StatefulWidget {
  final DemoCatalog catalog;
  const Resources(this.catalog, {super.key});
  @override
  State<Resources> createState() => _ResourcesState();
}

class _ResourcesState extends State<Resources> {
  // 1. DATA AND FILTER VALUES
  List<Map<String, dynamic>> get resources => widget.catalog.resources;
  String searchText = '';
  String selectedType = 'All';
  String selectedCapacity = 'Any';
  String selectedLocation = 'All Locations';
  String selectedPrice = 'Any Price';

  // 2. SEARCH AND FILTER LOGIC
  List<Map<String, dynamic>> get visibleResources {
    return resources.where((resource) {
      String type = resource.containsKey('projector') ? 'Meeting Room' : 'Desk';

      bool nameMatches = resource['name']
          .toString()
          .toLowerCase()
          .contains(searchText.toLowerCase());

      bool typeMatches = selectedType == 'All' || selectedType == type;

      bool capacityMatches = selectedCapacity == 'Any' ||
          resource['capacity'] >= int.parse(selectedCapacity);

      bool locationMatches = selectedLocation == 'All Locations' ||
          resource['location'].toString().toLowerCase() ==
              selectedLocation.toLowerCase();

      bool priceMatches = selectedPrice == 'Any Price' ||
          resource['hourlyRate'] <= double.parse(selectedPrice);

      return nameMatches &&
          typeMatches &&
          capacityMatches &&
          locationMatches &&
          priceMatches;
    }).toList();
  }

  // 3. MAIN SCREEN
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> shown = visibleResources;

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3.1 Page title
          Text(
            'Resources Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20),

          // 3.2 Search by name
          TextField(
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search resources by name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 20),

          // 3.3 Filters
          Wrap(
            spacing: 20,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              filterDropdown(
                'Resource Type',
                selectedType,
                ['All', 'Meeting Room', 'Desk'],
                (value) => setState(() => selectedType = value),
              ),

              filterDropdown(
                'Minimum Capacity',
                selectedCapacity,
                ['Any', '1', '2', '5', '10'],
                (value) => setState(() => selectedCapacity = value),
              ),

              filterDropdown(
                'Location',
                selectedLocation,
                ['All Locations', 'Floor 1', 'Floor 2', 'Floor 3'],
                (value) => setState(() => selectedLocation = value),
              ),

              filterDropdown(
                'Maximum Price',
                selectedPrice,
                ['Any Price', '50', '100', '200', '500'],
                (value) => setState(() => selectedPrice = value),
              ),
            ],
          ),

          SizedBox(height: 20),

          // 3.4 Add Resource button
          ElevatedButton.icon(
            onPressed: () => openResourceForm(),
            icon: Icon(Icons.add),
            label: Text('Add Resource'),
          ),

          SizedBox(height: 20),

          // 3.5 Available Resources heading
          Text(
            'Available Resources',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10),

          // 3.6 Resource cards
          Expanded(
            child: shown.isEmpty
                ? Center(child: Text('No resources available'))
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      return resourceCard(shown[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 4. FILTER DROPDOWN
  // Used for Type, Capacity, Location and Price
  Widget filterDropdown(
    String label,
    String selected,
    List<String> options,
    void Function(String) onSelect,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: '),

        SizedBox(width: 8),

        DropdownButton<String>(
          value: selected,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onSelect(value);
            }
          },
        ),
      ],
    );
  }

  // 5. RESOURCE CARD
  Widget resourceCard(Map<String, dynamic> resource) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 5.1 Resource details
            Text(
              resource['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text('Location: ${resource['location']}'),
            Text('Capacity: ${resource['capacity']}'),
            Text('Hourly Rate: ${resource['hourlyRate']} QAR'),
            Text('Status: ${resource['status']}'),

            // 5.2 Meeting Room details
            if (resource.containsKey('projector'))
              Text('Projector: ${resource['projector'] ? 'Yes' : 'No'}'),

            if (resource.containsKey('videoConference'))
              Text(
                'Video Conference: ${resource['videoConference'] ? 'Yes' : 'No'}',
              ),

            // 5.3 Desk details
            if (resource.containsKey('deskType'))
              Text('Desk Type: ${resource['deskType']}'),

            SizedBox(height: 10),

            // 5.4 Edit and Delete buttons
            Wrap(
              spacing: 10,
              children: [
                // 5.4.1 Edit button
                ElevatedButton.icon(
                  onPressed: () {
                    openResourceForm(existing: resource);
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Edit'),
                ),

                // 5.4.2 Delete button
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.catalog.bookings.any((b) => b.slot.resourceId.toString() == resource['id'].toString())) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This resource has booking history and cannot be deleted.')));
                      return;
                    }
                    setState(() {
                      resources.remove(resource);
                    });
                  },
                  icon: Icon(Icons.delete),
                  label: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 6. ADD AND EDIT RESOURCE FORM
  // Same form is used for adding and editing
  Future<void> openResourceForm({Map<String, dynamic>? existing}) async {
    // 6.1 Get existing values (empty when adding)
    bool editing = existing != null;

    TextEditingController name =
        TextEditingController(text: existing?['name'] ?? '');

    TextEditingController location =
        TextEditingController(text: existing?['location'] ?? '');

    TextEditingController capacity = TextEditingController(
      text: existing?['capacity']?.toString() ?? '',
    );

    TextEditingController rate = TextEditingController(
      text: existing?['hourlyRate']?.toString() ?? '',
    );

    // 6.2 Resource type and extra options
    String type = editing && existing.containsKey('deskType')
        ? 'Desk'
        : 'Meeting Room';

    bool projector = existing?['projector'] ?? false;
    bool videoConference = existing?['videoConference'] ?? false;
    String deskType = existing?['deskType'] ?? 'Regular Desk';

    // 6.3 Open Add/Edit popup
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, updateDialog) {
            return AlertDialog(
              title: Text(
                editing ? 'Edit Resource' : 'Add New Resource',
              ),

              content: SingleChildScrollView(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 6.4 Resource name
                      inputField('Resource Name', name),

                      SizedBox(height: 15),

                      // 6.5 Resource type
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: InputDecoration(
                          labelText: 'Resource Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Meeting Room', 'Desk'].map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: editing
                            ? null
                            : (value) {
                                if (value != null) {
                                  updateDialog(() {
                                    type = value;
                                  });
                                }
                              },
                      ),

                      SizedBox(height: 15),

                      // 6.6 Location
                      inputField('Location', location),

                      SizedBox(height: 15),

                      // 6.7 Capacity
                      inputField('Capacity', capacity, numeric: true),

                      SizedBox(height: 15),

                      // 6.8 Hourly rate
                      inputField('Hourly Rate (QAR)', rate, numeric: true),

                      SizedBox(height: 10),

                      // 6.9 Meeting Room options
                      if (type == 'Meeting Room') ...[
                        // 6.9.1 Projector
                        CheckboxListTile(
                          title: Text('Projector'),
                          value: projector,
                          onChanged: (value) {
                            updateDialog(() {
                              projector = value ?? false;
                            });
                          },
                        ),

                        // 6.9.2 Video Conference
                        CheckboxListTile(
                          title: Text('Video Conference'),
                          value: videoConference,
                          onChanged: (value) {
                            updateDialog(() {
                              videoConference = value ?? false;
                            });
                          },
                        ),
                      ],

                      // 6.10 Desk options
                      if (type == 'Desk')
                        DropdownButtonFormField<String>(
                          initialValue: deskType,
                          decoration: InputDecoration(
                            labelText: 'Desk Type',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            'Regular Desk',
                            'Standing Desk',
                            'Private Desk',
                          ].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              updateDialog(() {
                                deskType = value;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),

              actions: [
                // 6.11 Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Cancel'),
                ),

                // 6.12 Save button
                ElevatedButton(
                  onPressed: () {
                    // 6.12.1 Read entered values
                    String newName = name.text.trim();
                    String newLocation = location.text.trim();
                    int? newCapacity = int.tryParse(capacity.text);
                    double? newRate = double.tryParse(rate.text);

                    // 6.12.2 Check entered values
                    if (newName.isEmpty ||
                        newLocation.isEmpty ||
                        newCapacity == null ||
                        newCapacity <= 0 ||
                        newRate == null ||
                        newRate <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter valid information'),
                        ),
                      );
                      return;
                    }

                    // 6.12.3 Prepare resource data
                    Map<String, dynamic> data = {
                      'id': existing?['id'] ?? widget.catalog.nextResourceId++,
                      'name': newName,
                      'location': newLocation,
                      'capacity': newCapacity,
                      'hourlyRate': newRate,
                      'status': existing?['status'] ?? 'ACTIVE',
                    };

                    // 6.12.4 Meeting Room data
                    if (type == 'Meeting Room') {
                      data['projector'] = projector;
                      data['videoConference'] = videoConference;
                    }

                    // 6.12.5 Desk data
                    else {
                      data['deskType'] = deskType;
                    }

                    // 6.12.6 Add or update resource
                    setState(() {
                      if (editing) {
                        existing.clear();
                        existing.addAll(data);
                      } else {
                        resources.add(data);
                      }
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // 6.13 Clean up controllers
    name.dispose();
    location.dispose();
    capacity.dispose();
    rate.dispose();
  }

  // 7. REUSABLE TEXT FIELD
  // Used in both Add and Edit forms
  Widget inputField(
    String label,
    TextEditingController controller, {
    bool numeric = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}