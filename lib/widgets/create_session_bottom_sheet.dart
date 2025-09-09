import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayoo/providers/session_provider.dart';
import 'package:provider/provider.dart';

class CreateSessionBottomSheet extends StatefulWidget {
  const CreateSessionBottomSheet({super.key});

  @override
  _CreateSessionBottomSheetState createState() => _CreateSessionBottomSheetState();
}

class _CreateSessionBottomSheetState extends State<CreateSessionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _prayerPoints = [''];
  DateTime _scheduledTime = DateTime.now().add(Duration(hours: 1));
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Create Prayer Session',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Session Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text('Scheduled Time'),
                    subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(_scheduledTime)),
                    trailing: Icon(Icons.schedule),
                    onTap: _selectDateTime,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Prayer Points',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ..._buildPrayerPointFields(),
                  SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addPrayerPoint,
                    icon: Icon(Icons.add),
                    label: Text('Add Prayer Point'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Create Session',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildPrayerPointFields() {
    return _prayerPoints.asMap().entries.map((entry) {
      int index = entry.key;
      return Container(
        margin: EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: entry.value,
                decoration: InputDecoration(
                  labelText: 'Prayer Point ${index + 1}',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _prayerPoints[index] = value;
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a prayer point';
                  }
                  return null;
                },
              ),
            ),
            if (_prayerPoints.length > 1)
              IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removePrayerPoint(index),
              ),
          ],
        ),
      );
    }).toList();
  }
  
  void _addPrayerPoint() {
    setState(() {
      _prayerPoints.add('');
    });
  }
  
  void _removePrayerPoint(int index) {
    setState(() {
      _prayerPoints.removeAt(index);
    });
  }
  
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      );
      
      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await context.read<SessionProvider>().createPrayerSession(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledTime: _scheduledTime,
        prayerPoints: _prayerPoints.where((point) => point.isNotEmpty).toList(),
      );
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prayer session created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}