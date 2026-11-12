import 'package:flutter/material.dart';
import '../services/demo_catalog.dart';
import '../services/resource_api.dart';

class Resources extends StatefulWidget {
  final DemoCatalog catalog;

  const Resources(this.catalog, {super.key});

  @override
  State<Resources> createState() => _ResourcesState();
}

class _ResourcesState extends State<Resources> {
  // 1. DATA AND FILTER VALUES
  final ResourceApi resourceApi = ResourceApi();

  List<Map<String, dynamic>> resources = [];

  bool isLoading = true;
  String? errorMessage;

  String searchText = '';
  String selectedType = 'All';
  String selectedCapacity = 'Any';
  String selectedLocation = 'All Locations';
  String selectedPrice = 'Any Price';

  // 2. LOAD RESOURCES FROM BACKEND
  @override
  void initState() {
    super.initState();
    loadResources();
  }

  Future<void> loadResources() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await resourceApi.getResources();

      if (!mounted) return;

      setState(() {
        resources = data.map((item) {
          return Map<String, dynamic>.from(item);
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

  // 3. SEARCH AND FILTER LOGIC
  List<Map<String, dynamic>> get visibleResources {
    return resources.where((resource) {
      String type =
          resource.containsKey('projector') ? 'Meeting Room' : 'Desk';

      bool nameMatches = resource['name']
          .toString()
          .toLowerCase()
          .contains(searchText.toLowerCase());

      bool typeMatches = selectedType == 'All' || selectedType == type;

      bool capacityMatches = selectedCapacity == 'Any' ||
          (resource['capacity'] as num).toInt() >=
              int.parse(selectedCapacity);

      bool locationMatches = selectedLocation == 'All Locations' ||
          resource['location'].toString().toLowerCase() ==
              selectedLocation.toLowerCase();

      bool priceMatches = selectedPrice == 'Any Price' ||
          (resource['hourlyRate'] as num).toDouble() <=
              double.parse(selectedPrice);

      return nameMatches &&
          typeMatches &&
          capacityMatches &&
          locationMatches &&
          priceMatches;
    }).toList();
  }

  // 4. MAIN SCREEN
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> shown = visibleResources;

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4.1 Page title
          Text(
            'Resources Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20),

          // 4.2 Search by name
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

          // 4.3 Filters
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

          // 4.4 Add Resource button
          ElevatedButton.icon(
            onPressed: () => openResourceForm(),
            icon: Icon(Icons.add),
            label: Text('Add Resource'),
          ),

          SizedBox(height: 20),

          // 4.5 Available Resources heading
          Text(
            'Available Resources',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10),

          // 4.6 Resource cards
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Could not load resources'),
                            SizedBox(height: 10),
                            Text(errorMessage!),
                            ElevatedButton(
                              onPressed: loadResources,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : shown.isEmpty
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

  // 5. FILTER DROPDOWN
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

  // 6. RESOURCE CARD
  Widget resourceCard(Map<String, dynamic> resource) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 6.1 Resource details
            Text(
              resource['name'].toString(),
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

            // 6.2 Meeting Room details
            if (resource.containsKey('projector'))
              Text(
                'Projector: ${resource['projector'] == true ? 'Yes' : 'No'}',
              ),

            if (resource.containsKey('videoConference'))
              Text(
                'Video Conference: ${resource['videoConference'] == true ? 'Yes' : 'No'}',
              ),

            // 6.3 Desk details
            if (resource.containsKey('deskType'))
              Text('Desk Type: ${resource['deskType']}'),

            SizedBox(height: 10),

            // 6.4 Edit and Delete buttons
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    openResourceForm(existing: resource);
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Edit'),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    deleteResource(resource);
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

  // 7. DELETE RESOURCE
  Future<void> deleteResource(Map<String, dynamic> resource) async {
    // 7.1 Check local booking history
    bool hasBooking = widget.catalog.bookings.any(
      (b) => b.slot.resourceId.toString() ==
          resource['id'].toString(),
    );

    if (hasBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This resource has booking history and cannot be deleted.',
          ),
        ),
      );
      return;
    }

    // 7.2 Delete from backend
    try {
      await resourceApi.deleteResource(
        (resource['id'] as num).toInt(),
      );

      if (!mounted) return;

      await loadResources();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resource deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete resource: $e')),
      );
    }
  }

  // 8. ADD AND EDIT RESOURCE FORM
  Future<void> openResourceForm({
    Map<String, dynamic>? existing,
  }) async {
    // 8.1 Get existing values
    bool editing = existing != null;

    TextEditingController name = TextEditingController(
      text: existing?['name'] ?? '',
    );

    TextEditingController location = TextEditingController(
      text: existing?['location'] ?? '',
    );

    TextEditingController capacity = TextEditingController(
      text: existing?['capacity']?.toString() ?? '',
    );

    TextEditingController rate = TextEditingController(
      text: existing?['hourlyRate']?.toString() ?? '',
    );

    // 8.2 Resource type and extra options
    String type = editing && existing.containsKey('deskType')
        ? 'Desk'
        : 'Meeting Room';

    bool projector = existing?['projector'] ?? false;
    bool videoConference = existing?['videoConference'] ?? false;
    String deskType = existing?['deskType'] ?? 'Regular Desk';

    // 8.3 Open Add/Edit popup
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
                      // 8.4 Resource name
                      inputField('Resource Name', name),

                      SizedBox(height: 15),

                      // 8.5 Resource type
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

                      // 8.6 Location
                      inputField('Location', location),

                      SizedBox(height: 15),

                      // 8.7 Capacity
                      inputField(
                        'Capacity',
                        capacity,
                        numeric: true,
                      ),

                      SizedBox(height: 15),

                      // 8.8 Hourly rate
                      inputField(
                        'Hourly Rate (QAR)',
                        rate,
                        numeric: true,
                      ),

                      SizedBox(height: 10),

                      // 8.9 Meeting Room options
                      if (type == 'Meeting Room') ...[
                        CheckboxListTile(
                          title: Text('Projector'),
                          value: projector,
                          onChanged: (value) {
                            updateDialog(() {
                              projector = value ?? false;
                            });
                          },
                        ),

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

                      // 8.10 Desk options
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
                // 8.11 Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Cancel'),
                ),

                // 8.12 Save button
                ElevatedButton(
                  onPressed: () async {
                    // 8.12.1 Read entered values
                    String newName = name.text.trim();
                    String newLocation = location.text.trim();
                    int? newCapacity = int.tryParse(capacity.text);
                    double? newRate = double.tryParse(rate.text);

                    // 8.12.2 Check entered values
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

                    // 8.12.3 Prepare resource data
                    Map<String, dynamic> data = {
                      'name': newName,
                      'location': newLocation,
                      'capacity': newCapacity,
                      'hourlyRate': newRate,
                      'status': existing?['status'] ?? 'ACTIVE',
                    };

                    if (type == 'Meeting Room') {
                      data['projector'] = projector;
                      data['videoConference'] = videoConference;
                    } else {
                      data['deskType'] = deskType;
                    }

                    // 8.12.4 Save to backend
                    try {
                      if (editing) {
                        int id = (existing['id'] as num).toInt();

                        if (type == 'Meeting Room') {
                          await resourceApi.updateMeetingRoom(id, data);
                        } else {
                          await resourceApi.updateDesk(id, data);
                        }
                      } else {
                        if (type == 'Meeting Room') {
                          await resourceApi.addMeetingRoom(data);
                        } else {
                          await resourceApi.addDesk(data);
                        }
                      }

                      if (!mounted || !dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      await loadResources();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            editing
                                ? 'Resource updated successfully'
                                : 'Resource added successfully',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not save resource: $e'),
                        ),
                      );
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // 8.13 Clean up controllers
    name.dispose();
    location.dispose();
    capacity.dispose();
    rate.dispose();
  }

  // 9. REUSABLE TEXT FIELD
  Widget inputField(
    String label,
    TextEditingController controller, {
    bool numeric = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}