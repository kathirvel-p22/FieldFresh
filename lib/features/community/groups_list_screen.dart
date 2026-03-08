import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});
  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allGroups = [];
  List<Map<String, dynamic>> _myGroups = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final _categories = [
    'All',
    'Organic Farming',
    'Vegetables',
    'Fruits',
    'Dairy',
    'Market Tips',
    'Equipment'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = SupabaseService.currentUserId;

      // Load all public groups
      final allGroupsData = await supabase
          .from('community_groups')
          .select('*')
          .eq('is_active', true)
          .eq('is_public', true)
          .order('member_count', ascending: false);

      // Load user's groups
      List<Map<String, dynamic>> myGroupsData = [];
      if (userId != null) {
        final memberData = await supabase
            .from('group_members')
            .select('group_id, community_groups(*)')
            .eq('user_id', userId);

        myGroupsData = memberData
            .map((m) => m['community_groups'] as Map<String, dynamic>)
            .toList();
      }

      setState(() {
        _allGroups = List<Map<String, dynamic>>.from(allGroupsData);
        _myGroups = myGroupsData;
        _loading = false;
      });
    } catch (e) {
      print('Error loading groups: $e');
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredGroups {
    var groups = _selectedCategory == 'All' 
        ? _allGroups 
        : _allGroups.where((g) => g['category'] == _selectedCategory).toList();
    
    if (_searchQuery.isNotEmpty) {
      groups = groups.where((g) {
        final name = (g['name'] ?? '').toString().toLowerCase();
        final description = (g['description'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }
    
    return groups;
  }

  Future<void> _joinGroup(String groupId) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });

      _loadGroups();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('Success!'),
              ],
            ),
            content: const Text('Joined group successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error joining group: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: AppColors.error),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Failed to join group:\n\n${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community Groups'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Groups'),
            Tab(text: 'My Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllGroupsTab(),
          _buildMyGroupsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          ).then((_) => _loadGroups());
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
      ),
    );
  }

  Widget _buildAllGroupsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search groups...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),
        // Category filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        // Groups list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('👥', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'No groups found for "$_searchQuery"'
                                : 'No groups found',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadGroups,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = _filteredGroups[index];
                          final isMember =
                              _myGroups.any((g) => g['id'] == group['id']);
                          return _buildGroupCard(group, isMember);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMyGroupsTab() {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _myGroups.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👥', style: TextStyle(fontSize: 64)),
                    SizedBox(height: 12),
                    Text('You haven\'t joined any groups yet',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Browse groups and join to start chatting!',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadGroups,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myGroups.length,
                  itemBuilder: (context, index) {
                    final group = _myGroups[index];
                    return _buildGroupCard(group, true);
                  },
                ),
              );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, bool isMember) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isMember
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(
                      groupId: group['id'],
                      groupName: group['name'],
                    ),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Group icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getCategoryIcon(group['category']),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'] ?? 'Group',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people,
                            size: 14, color: AppColors.textHint),
                        Text(
                          ' ${group['member_count'] ?? 0} members',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            group['category'] ?? '',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Join/Open button
              if (isMember)
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.textHint)
              else
                ElevatedButton(
                  onPressed: () => _joinGroup(group['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Join',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryIcon(String? category) {
    const icons = {
      'Organic Farming': '🌱',
      'Vegetables': '🥬',
      'Fruits': '🍎',
      'Dairy': '🥛',
      'Market Tips': '💰',
      'Equipment': '🚜',
      'Seeds': '🌾',
      'Pest Control': '🐛',
      'Weather': '🌤️',
      'Recipes': '🍳',
    };
    return icons[category] ?? '👥';
  }
}
