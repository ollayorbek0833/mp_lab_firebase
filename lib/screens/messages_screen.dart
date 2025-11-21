import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _addMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('messages').add({
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  Future<void> _updateMessage(String docId, String currentText) async {
    final ctrl = TextEditingController(text: currentText);
    final res = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit message'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Message',
            ),
            onSubmitted: (_) => Navigator.of(context).pop(ctrl.text.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(ctrl.text.trim()), child: const Text('Save')),
          ],
        );
      },
    );

    if (res == null) return;
    final newText = res.trim();
    if (newText.isEmpty || newText == currentText) return;
    await FirebaseFirestore.instance.collection('messages').doc(docId).update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteMessage(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This will permanently remove the message.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('messages').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages (CRUD)")),
      body: Column(
        children: [
          // Input box + Add button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: "Enter message",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addMessage,
                  child: const Text("Add"),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Real-time messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading messages"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final text = (data['text'] ?? '').toString();
                    final timestamp = data['timestamp'];
                    final editedAt = data['editedAt'];

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        // confirm before deleting
                        return await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Delete message?'),
                            content: const Text('This will permanently remove the message.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
                            ],
                          ),
                        ) ??
                            false;
                      },
                      onDismissed: (_) => FirebaseFirestore.instance.collection('messages').doc(doc.id).delete(),
                      child: ListTile(
                        title: Text(text),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.id, style: const TextStyle(fontSize: 12)),
                            if (timestamp != null)
                              Text(
                                DateTime.fromMillisecondsSinceEpoch((timestamp as Timestamp).millisecondsSinceEpoch).toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (editedAt != null)
                              Text(
                                'edited: ${DateTime.fromMillisecondsSinceEpoch((editedAt as Timestamp).millisecondsSinceEpoch).toString()}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () => _updateMessage(doc.id, text),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _updateMessage(doc.id, text),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
