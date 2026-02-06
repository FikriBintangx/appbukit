import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_voting.dart';
import '../services.dart';


class VotingListScreen extends StatelessWidget {
  final String currentUserId;
  final bool isAdmin;

  const VotingListScreen({
    super.key,
    required this.currentUserId,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Voting & Polling'),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateVotingDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Buat Voting'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('votings')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final votings = snapshot.data!.docs
              .map((doc) => VotingModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();

          if (votings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_vote_outlined,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada voting',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap tombol + untuk membuat voting',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: votings.length,
            itemBuilder: (context, index) {
              final voting = votings[index];
              return _buildVotingCard(context, voting);
            },
          );
        },
      ),
    );
  }

  Widget _buildVotingCard(BuildContext context, VotingModel voting) {
    final hasEnded = voting.hasEnded;
    final daysLeft = voting.endDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VotingDetailScreen(
              voting: voting,
              currentUserId: currentUserId,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasEnded
                          ? Colors.grey.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.how_to_vote,
                      color: hasEnded ? Colors.grey : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voting.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasEnded
                              ? 'Voting telah berakhir'
                              : daysLeft == 0
                                  ? 'Berakhir hari ini'
                                  : 'Berakhir dalam $daysLeft hari',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasEnded ? Colors.grey : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasEnded
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasEnded ? 'SELESAI' : 'AKTIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasEnded ? Colors.grey : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                voting.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${voting.totalVotes} suara',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.list_alt, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${voting.options.length} pilihan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateVotingDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final option1Ctrl = TextEditingController();
    final option2Ctrl = TextEditingController();
    final List<TextEditingController> optionCtrls = [option1Ctrl, option2Ctrl];
    int daysUntilEnd = 7;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Buat Voting Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Judul Voting',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilihan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(optionCtrls.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: optionCtrls[index],
                        decoration: InputDecoration(
                          labelText: 'Pilihan ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        optionCtrls.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Pilihan'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Durasi: '),
                      Expanded(
                        child: Slider(
                          value: daysUntilEnd.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: '$daysUntilEnd hari',
                          onChanged: (value) {
                            setState(() {
                              daysUntilEnd = value.toInt();
                            });
                          },
                        ),
                      ),
                      Text('$daysUntilEnd hari'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Judul harus diisi')),
                    );
                    return;
                  }

                  final options = optionCtrls
                      .map((c) => c.text.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  if (options.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Minimal 2 pilihan diperlukan')),
                    );
                    return;
                  }

                  final voting = VotingModel(
                    id: '',
                    title: titleCtrl.text,
                    description: descCtrl.text,
                    options: options,
                    createdAt: DateTime.now(),
                    endDate: DateTime.now().add(Duration(days: daysUntilEnd)),
                    createdBy: currentUserId,
                    isActive: true,
                    votes: {for (var opt in options) opt: 0},
                  );

                  await FirebaseFirestore.instance
                      .collection('votings')
                      .add(voting.toMap());

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Voting berhasil dibuat!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Buat'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class VotingDetailScreen extends StatefulWidget {
  final VotingModel voting;
  final String currentUserId;

  const VotingDetailScreen({
    super.key,
    required this.voting,
    required this.currentUserId,
  });

  @override
  State<VotingDetailScreen> createState() => _VotingDetailScreenState();
}

class _VotingDetailScreenState extends State<VotingDetailScreen> {
  String? selectedOption;
  bool hasVoted = false;

  @override
  void initState() {
    super.initState();
    _checkIfVoted();
  }

  Future<void> _checkIfVoted() async {
    final doc = await FirebaseFirestore.instance
        .collection('vote_records')
        .where('voting_id', isEqualTo: widget.voting.id)
        .where('user_id', isEqualTo: widget.currentUserId)
        .get();

    if (doc.docs.isNotEmpty) {
      setState(() {
        hasVoted = true;
        selectedOption = doc.docs.first.data()['selected_option'];
      });
    }
  }

  Future<void> _submitVote() async {
    if (selectedOption == null) return;

    try {
      // Save vote record
      await FirebaseFirestore.instance.collection('vote_records').add({
        'voting_id': widget.voting.id,
        'user_id': widget.currentUserId,
        'selected_option': selectedOption,
        'timestamp': Timestamp.now(),
      });

      // Update vote count
      await FirebaseFirestore.instance
          .collection('votings')
          .doc(widget.voting.id)
          .update({
        'votes.$selectedOption': FieldValue.increment(1),
      });

      setState(() {
        hasVoted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Suara Anda berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan suara: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Voting'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('votings')
            .doc(widget.voting.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final voting = VotingModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Description
                Text(
                  voting.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  voting.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Info Card
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Berakhir: ${Utils.formatDateTime(voting.endDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Total suara: ${voting.totalVotes}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Options
                const Text(
                  'Pilihan:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ...voting.options.map((option) {
                  final voteCount = voting.votes[option] ?? 0;
                  final percentage = voting.totalVotes > 0
                      ? (voteCount / voting.totalVotes * 100)
                      : 0.0;

                  return _buildOptionCard(
                    option,
                    voteCount,
                    percentage,
                    hasVoted || voting.hasEnded,
                  );
                }),

                const SizedBox(height: 24),

                // Submit Button
                if (!hasVoted && !voting.hasEnded)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedOption != null ? _submitVote : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Kirim Suara',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (hasVoted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Anda sudah memberikan suara',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (voting.hasEnded)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock, color: Colors.grey[700]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Voting telah berakhir',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionCard(
    String option,
    int voteCount,
    double percentage,
    bool showResults,
  ) {
    final isSelected = selectedOption == option;

    return GestureDetector(
      onTap: (!hasVoted && !widget.voting.hasEnded)
          ? () {
              setState(() {
                selectedOption = option;
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!hasVoted && !widget.voting.hasEnded)
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                if (!hasVoted && !widget.voting.hasEnded)
                  const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (showResults)
                  Text(
                    '$voteCount (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
            if (showResults) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
