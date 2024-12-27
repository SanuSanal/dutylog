import 'package:anjus_duties/service/google_sheet_api.dart';
import 'package:flutter/material.dart';

class EditDutyPage extends StatefulWidget {
  final DateTime editingDate;
  final String dutyType;
  final String comment;
  final String spreadsheetId;

  const EditDutyPage(
      {super.key,
      required this.editingDate,
      required this.dutyType,
      required this.comment,
      required this.spreadsheetId});

  @override
  EditDutyPageState createState() => EditDutyPageState();
}

class EditDutyPageState extends State<EditDutyPage> {
  late String _selectedDuty;
  late TextEditingController _commentController;
  GoogleSheetApi sheetApi = GoogleSheetApi();

  @override
  void initState() {
    super.initState();

    _selectedDuty = widget.dutyType;
    _commentController = TextEditingController(
      text: widget.comment,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Duty'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<int>(
                    label: 'Day',
                    value: widget.editingDate.day,
                    items: List.generate(31, (index) => index + 1)
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      );
                    }).toList(),
                    isDisabled: true,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _buildDropdown<String>(
                    label: 'Duty',
                    value: _selectedDuty,
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'M',
                        child: Text('Morning duty'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'E',
                        child: Text('Evening duty'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'D',
                        child: Text('Day duty'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'N',
                        child: Text('Night duty'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'O',
                        child: Text('Off day'),
                      ),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedDuty = newValue ?? 'D';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _commentController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    String comment = _commentController.text;
                    var sheetRowData = [
                      widget.editingDate.day,
                      _selectedDuty,
                      comment
                    ];
                    var isUpdated = await GoogleSheetApi.updateSheetRange(
                        widget.editingDate, sheetRowData, widget.spreadsheetId);

                    if (context.mounted) {
                      Navigator.pop(context, isUpdated);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
      {required String label,
      required T value,
      required List<DropdownMenuItem<T>> items,
      ValueChanged<T?>? onChanged,
      bool isDisabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.grey[400]!,
            ),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items,
            onChanged: isDisabled ? null : onChanged,
          ),
        ),
      ],
    );
  }
}
