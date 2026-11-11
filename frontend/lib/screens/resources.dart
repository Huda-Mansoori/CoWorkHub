import 'package:flutter/material.dart';

class Resources extends StatefulWidget {
  @override
  State<Resources> createState() {
    return _ResourcesState();
  }
}

class _ResourcesState extends State<Resources> {
  String selectedType = 'All'; // Stores the selected resource type

  String selectedCapacity = 'Any'; // Stores the selected minimum capacity
  String selectedLocation = 'All Locations'; // Stores the selected location
  String selectedPrice = 'Any Price'; // Stores the selected price
  final resourceNameController =
      TextEditingController(); // reads the resource name entered by the user
  String newResourceType = 'Meeting Room'; // resource type for new rescource
  final resourceLocationController = TextEditingController();
  final resourceCapacityController =
      TextEditingController(); //reads the capacity entered by controller
  final resourceRateController =
      TextEditingController(); // reads hourly rate entered by user
  String newResourceStatus =
      'ACTIVE'; // stores the operational status of new resource
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Page title - Resources Management
          Text(
            'Resources Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20),

          // 2. Search bar - Search resources by name
          TextField(
            decoration: InputDecoration(
              hintText: 'Search resources by name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 20),

          // 3. Filter options
          Row(
            children: [
              // 3.1 - Filter by resource type - Meeting Room or Desk
              // Label for resource type
              Text('Resource Type: '),
              SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedType,

                // Available resource types
                items: ['All', 'Meeting Room', 'Desk'].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),

                // Runs when the user selects a resource type
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                  });
                },
              ),

              // 3.2 - Filter by minimum capacity
              SizedBox(width: 20),
              // Label for minimum capacity
              Text('Minimum Capacity: '),
              SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedCapacity,
                items: ['Any', '1', '2', '5', '10'].map((capacity) {
                  return DropdownMenuItem<String>(
                    value: capacity,
                    child: Text(capacity),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCapacity = value!;
                  });
                },
              ),

              // 3.3 - Filter by location
              SizedBox(width: 20),
              Text('Location: '),
              SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedLocation,
                // availaible locations
                items: ['All Locations', 'Floor 1', 'Floor 2', 'Floor 3'].map((
                  location,
                ) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLocation = value!;
                  });
                },
              ),

              // 3.4 - Filter by price
              SizedBox(width: 20),
              Text('Maximum Price: '),
              SizedBox(width: 10),

              DropdownButton<String>(
                value: selectedPrice,

                // available price options
                items: ['Any Price', '50', '100', '200', '500'].map((price) {
                  return DropdownMenuItem<String>(
                    value: price,
                    child: Text(price),
                  );
                }).toList(),
                //update the selected price
                onChanged: (value) {
                  setState(() {
                    selectedPrice = value!;
                  });
                },
              ),
            ],
          ),

          // 4. Add Resource button
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // 4.1 Add Resource form
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setDialogState) {
                      return AlertDialog(
                        title: Text('Add New Resource'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // resource name
                              TextField(
                                controller: resourceNameController,
                                decoration: InputDecoration(
                                  labelText: 'Resource Name',
                                  hintText: 'Enter resource name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 20),

                              // recource type
                              DropdownButtonFormField<String>(
                                initialValue: newResourceType,

                                //available resource type
                                items: ['Meeting Room', 'Desk'].map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),

                                // updates the selected resource type
                                onChanged: (value) {
                                  setDialogState(() {
                                    newResourceType = value!;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Resource Type',
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              SizedBox(height: 20),
                              // Resource Location
                              TextField(
                                controller: resourceLocationController,
                                decoration: InputDecoration(
                                  labelText: 'Location',
                                  hintText: 'Enter Location',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              //Enter resource capacity
                              SizedBox(height: 20),

                              TextField(
                                controller: resourceCapacityController,

                                decoration: InputDecoration(
                                  labelText: 'Capacity',
                                  hintText: 'Enter capacity',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              // Hourly rate
                              SizedBox(height: 20),
                              TextField(
                                controller: resourceRateController,
                                decoration: InputDecoration(
                                  labelText: 'Hourly Rate (QAR)',
                                  hintText: 'Entered hourly rate',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          //cancel button
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('cancel'),
                          ),
                          // Save resource button
                          ElevatedButton(
                            onPressed: () {
                              // Get the resource name entered by the user
                              String resourceName = resourceNameController.text;
                              String resourceType = newResourceType;
                              String resourceLocation =
                                  resourceLocationController.text;
                              String resourceCapacity =
                                  resourceCapacityController.text;
                              String resourceRate = resourceRateController.text;
                              String resourceStatus = newResourceStatus;
                              // chek if resource name empty??
                              if (resourceName.trim().isEmpty) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please enter resource name'),
                                  ),
                                );
                                return;
                              }
                              // check if location is empty
                              if (resourceLocation.trim().isEmpty) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please enter resource location',
                                    ),
                                  ),
                                );
                                return;
                              }
                              // check if capacity = null or less thn equal zero
                              int? capacity = int.tryParse(resourceCapacity);
                              if (capacity == null || capacity <= 0) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please enter valid capacity',
                                    ),
                                  ),
                                );
                                return;
                              }
                              // check if hourly rate is valid number
                              double? hourlyRate = double.tryParse(
                                resourceRate,
                              );
                              if (hourlyRate == null || hourlyRate <= 0) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Enter valid hourly rate'),
                                  ),
                                );
                                return;
                              }

                              print(resourceName);
                              print(resourceType);
                              print(resourceLocation);
                              print(resourceCapacity);
                              print(resourceRate);
                              print(resourceStatus);
                            },
                            child: Text('save'),
                          ),
                        ],
                      ); // Closes AlertDialog
                    },
                  ); // Closes StatefulBuilder
                },
              ); // Closes showDialog
            },
            icon: Icon(Icons.add),
            label: Text('Add Resource'),
          ),

          // 5. Resources list with details

          // 6. Edit and Delete buttons

          // 7. Success and error messages
        ],
      ),
    );
  }

  @override
  void dispose() {
    resourceNameController.dispose();
    resourceLocationController.dispose();
    resourceCapacityController.dispose();
    resourceRateController.dispose();

    super.dispose();
  }
}
