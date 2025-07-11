import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../services/user/auth_provider.dart';
import '../../services/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

extension MediaQueryBoldTextOverride on MediaQuery {
  static bool boldTextOverride(BuildContext context) => MediaQuery.of(context).boldText;
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final userAchievementsAsync = ref.watch(userAchievementsProvider);

    // Today's stats providers
    final burnAsync = ref.watch(todayActivityCaloriesProvider);
    final nutritionAsync = ref.watch(nutritionStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.pink),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.pink),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              context.go('/');
            },
          )
        ],
      ),
      body: authAsync.when(
        data: (authState) {
          if (authState.profile == null) {
            return Center(child: Text('No profile loaded', style: TextStyle(color: Colors.pink)));
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: (authState.profile!['avatarUrl'] != null && authState.profile!['avatarUrl'].isNotEmpty)
                          ? NetworkImage(authState.profile!['avatarUrl'])
                          : null,
                      radius: 50,
                      backgroundColor: Colors.pink[50],
                      child: (authState.profile!['avatarUrl'] == null || authState.profile!['avatarUrl'].isEmpty)
                          ? Icon(Icons.person, color: Colors.pink, size: 32)
                          : null,
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(authState.profile!['name'], style: TextStyle(fontSize: 21, color: Colors.pink)),
                        Text('Weight: ${authState.profile!['weight']?.toStringAsFixed(1) ?? "--"} kg', style: TextStyle(color: Colors.pink)),
                        Text('Height: ${authState.profile!['height']?.toStringAsFixed(1) ?? "--"} cm', style: TextStyle(color: Colors.pink)),
                      ],
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.pink),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (ctx) => EditProfileDialog(
                          profile: UserProfile.fromJson(authState.profile!),
                          onSave: (name, avatarUrl, weight, height) async {
                            await ref.read(userApiProvider).updateProfile(name, avatarUrl, weight, height);
                            ref.invalidate(authProvider);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  "Today's Stats",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                burnAsync.when(
                  data: (burned) {
                    return nutritionAsync.when(
                      data: (nutrition) {
                        final intake = (nutrition['calories'] as num?)?.toDouble() ?? 0.0;
                        final rawGoal = (nutrition['calorieGoal'] as num?)?.toDouble()
                            ?? (authState.profile?['dailyCalorieGoal'] as num?)?.toDouble()
                            ?? 1000.0;
                        final goal = rawGoal > 0 ? rawGoal : 1000.0;

                        final burnedClamped = burned.toDouble().clamp(0, goal);
                        final intakeClamped = intake.clamp(0, goal);

                        final burnedPct = (burnedClamped / goal * 100).toStringAsFixed(0);
                        final intakePct = (intakeClamped / goal * 100).toStringAsFixed(0);

                        Widget chartColumn({
                          required String title,
                          required double value,
                          required String pct,
                          required Color color,
                        }) {
                          return Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 1) Title ABOVE
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.pink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 40),

                                // 2) Pie chart + % label
                                SizedBox(
                                  height: 120,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          startDegreeOffset: -90,
                                          centerSpaceRadius: 40,
                                          sections: [
                                            PieChartSectionData(
                                              value: value,
                                              color: color,
                                              radius: 50,
                                              title: '',
                                            ),
                                            PieChartSectionData(
                                              value: goal - value,
                                              color: Colors.grey[200],
                                              radius: 50,
                                              title: '',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '$pct%',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 40),

                                // 3) Caption BELOW
                                Text(
                                  '${value.toInt()} / ${goal.toInt()} kcal',
                                  style: TextStyle(
                                    color: Colors.pink.shade200,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Row(
                          children: [
                            chartColumn(
                              title: 'Burned',
                              value: burnedClamped.toDouble(),
                              pct: burnedPct,
                              color: Colors.pink,
                            ),
                            SizedBox(width: 16),
                            chartColumn(
                              title: 'Intake',
                              value: intakeClamped.toDouble(),
                              pct: intakePct,
                              color: Colors.pinkAccent,
                            ),
                          ],
                        );
                      },
                      loading: () => Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text(
                        'Error loading intake data',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text(
                    'Error loading burned calories',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                SizedBox(height: 24),
                Text('Friends', style: TextStyle(fontSize: 18, color: Colors.pink, fontWeight: FontWeight.bold)),
                friendsAsync.when(
                  data: (friends) => friends.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No friends yet', style: TextStyle(color: Colors.pink)),
                            TextButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (ctx) => AddFriendDialog(ref: ref),
                              ),
                              child: Text('Add Friend', style: TextStyle(color: Colors.pink)),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            ...friends.map((f) => ListTile(
                                  title: Text(f.name, style: TextStyle(color: Colors.pink)),
                                  subtitle: Text(f.email, style: TextStyle(color: Colors.black54)),
                                  leading: Icon(Icons.person, color: Colors.pink),
                                )),
                            TextButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (ctx) => AddFriendDialog(ref: ref),
                              ),
                              child: Text('Add Friend', style: TextStyle(color: Colors.pink)),
                            ),
                          ],
                        ),
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (e, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No friends yet', style: TextStyle(color: Colors.pink)),
                      TextButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (ctx) => AddFriendDialog(ref: ref),
                        ),
                        child: Text('Add Friend', style: TextStyle(color: Colors.pink)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Achievements
                Text('Achievements', style: TextStyle(fontSize: 18, color: Colors.pink, fontWeight: FontWeight.bold)),
                userAchievementsAsync.when(
                  data: (achievements) {
                    final unlocked = achievements.where((a) => a.unlocked).toList();
                    return unlocked.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No achievements yet', style: TextStyle(color: Colors.pink)),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => context.push('/all_achievements'),
                                    child: Text('See All Achievements', style: TextStyle(color: Colors.pink)),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...unlocked.map((a) => ListTile(
                                    title: Text(a.title, style: TextStyle(color: Colors.pink)),
                                    leading: Icon(Icons.emoji_events, color: Colors.pink),
                                  )),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => context.push('/all_achievements'),
                                    child: Text('See All Achievements', style: TextStyle(color: Colors.pink)),
                                  ),
                                ],
                              ),
                            ],
                          );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Failed to load achievements', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) {
          if (e.toString().contains('Invalid token')) {
            Future.microtask(() async {
              final notifier = ref.read(authProvider.notifier);
              await notifier.logout();
              if (context.mounted) context.go('/');
            });
            return Center(child: CircularProgressIndicator());
          }
          return Center(child: Text('Error: $e', style: TextStyle(color: Colors.red)));
        },
      ),
    );
  }
}

class AddFriendDialog extends StatefulWidget {
  final WidgetRef ref;
  const AddFriendDialog({required this.ref, super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final _emailController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Friend', style: TextStyle(color: Colors.pink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Friend Email',
              labelStyle: TextStyle(color: Colors.pink),
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () async {
            setState(() {
              _loading = true;
              _error = null;
            });
            try {
              // Implement userApi request here
              await widget.ref.read(userApiProvider).sendFriendRequest(_emailController.text);
              Navigator.pop(context);
              widget.ref.refresh(friendsProvider);
            } catch (e) {
              setState(() {
                _error = e.toString().replaceFirst('Exception:', '').trim();
              });
            } finally {
              setState(() { _loading = false; });
            }
          },
          child: _loading
              ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Send', style: TextStyle(color: Colors.pink)),
        ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.pink)),
        ),
      ],
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final UserProfile profile;
  final void Function(String name, String avatarUrl, double? weight, double? height) onSave;
  const EditProfileDialog({required this.profile, required this.onSave, super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _avatarController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _avatarController = TextEditingController(text: widget.profile.avatarUrl);
    _weightController = TextEditingController(text: widget.profile.weight?.toString() ?? '');
    _heightController = TextEditingController(text: widget.profile.height?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Profile', style: TextStyle(color: Colors.pink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.pink)),
          ),
          TextField(
            controller: _avatarController,
            decoration: InputDecoration(labelText: 'Avatar URL', labelStyle: TextStyle(color: Colors.pink)),
          ),
          TextField(
            controller: _weightController,
            decoration: InputDecoration(labelText: 'Weight (kg)', labelStyle: TextStyle(color: Colors.pink)),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _heightController,
            decoration: InputDecoration(labelText: 'Height (cm)', labelStyle: TextStyle(color: Colors.pink)),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onSave(
              _nameController.text,
              _avatarController.text,
              double.tryParse(_weightController.text),
              double.tryParse(_heightController.text),
            );
            Navigator.pop(context);
          },
          child: Text('Save', style: TextStyle(color: Colors.pink)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.pink)),
        ),
      ],
    );
  }
}
