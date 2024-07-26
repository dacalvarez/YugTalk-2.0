import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import '../../Widgets/Drawer_Widget.dart';
import 'Activity Boards/ActivityBoards_Mod.dart';
import 'Activity Forms/ActivityForms_Mod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Statistics/Stats_Mod.dart';

class ActivityMode_Mod extends StatefulWidget {
  final bool cameFromActivityBoards;

  const ActivityMode_Mod({super.key, this.cameFromActivityBoards = false});

  @override
  _ActivityMode_ModState createState() => _ActivityMode_ModState();
}

class _ActivityMode_ModState extends State<ActivityMode_Mod>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
    late String userID;

    Future<void> _fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        userID = user.email!;
      });
    } else {
      print('No user is currently signed in.');
    }
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GText('Activity Mode'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              tabs: [
                Tab(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _tabController.animateTo(0);
                    },
                    child: Container(
                      decoration: const BoxDecoration(),
                      child: Align(
                        alignment: Alignment.center,
                        child: GText(
                          'Statistics',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18.0
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Tab(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _tabController.animateTo(1);
                    },
                    child: Container(
                      decoration: const BoxDecoration(),
                      child: Align(
                        alignment: Alignment.center,
                        child: GText(
                          'Activity Forms',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18.0
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Tab(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _tabController.animateTo(2);
                    },
                    child: Container(
                      decoration: const BoxDecoration(),
                      child: Align(
                        alignment: Alignment.center,
                        child: GText(
                          'Activity Boards',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18.0
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const DrawerWidget(),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const Stats_Mod(),
          const ActivityForms_Mod(),
          ActivityBoards_Mod(userID: userID),
        ],
      ),
    );
  }
}