[1mdiff --git a/lib/Screens/Home_Screen.dart b/lib/Screens/Home_Screen.dart[m
[1mindex f050de5..2e5f0fa 100644[m
[1m--- a/lib/Screens/Home_Screen.dart[m
[1m+++ b/lib/Screens/Home_Screen.dart[m
[36m@@ -24,9 +24,9 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
     with SingleTickerProviderStateMixin {[m
   late TabController _tabController;[m
   final TextEditingController editModePasswordController =[m
[31m-      TextEditingController();[m
[32m+[m[32m  TextEditingController();[m
   final TextEditingController activityModePasswordController =[m
[31m-      TextEditingController();[m
[32m+[m[32m  TextEditingController();[m
   bool _passwordVisible = false;[m
   List<WordUsage> wordUsages = generateDummyData();[m
   int _wordCount = 0;[m
[36m@@ -83,7 +83,7 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
 [m
     // Fetch location count[m
     final userSettingsRef =[m
[31m-        FirebaseFirestore.instance.collection('userSettings').doc(user.email);[m
[32m+[m[32m    FirebaseFirestore.instance.collection('userSettings').doc(user.email);[m
     _userSettingsSubscription = userSettingsRef.snapshots().listen((snapshot) {[m
       if (snapshot.exists) {[m
         _updateLocationCount(snapshot.data());[m
[36m@@ -108,7 +108,7 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
 [m
     for (var boardDoc in boardSnapshot.docs) {[m
       String boardId = boardDoc.id;[m
[31m-      String boardName = boardDoc['name'] as String? ?? 'Unnamed Board';[m
[32m+[m[32m      String boardName = boardDoc['name'];[m
 [m
       QuerySnapshot wordsSnapshot = await FirebaseFirestore.instance[m
           .collection('board')[m
[36m@@ -118,29 +118,20 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
 [m
       for (var wordDoc in wordsSnapshot.docs) {[m
         Map<String, dynamic> wordData = wordDoc.data() as Map<String, dynamic>;[m
[31m-[m
[31m-        // Skip placeholder words[m
[31m-        if (wordDoc.id == 'placeholder' || wordData['initialized'] == true) {[m
[31m-          continue;[m
[31m-        }[m
[31m-[m
[31m-        String wordName = wordData['wordName'] as String? ?? 'Unnamed Word';[m
[31m-        String wordCategory =[m
[31m-            wordData['wordCategory'] as String? ?? 'Uncategorized';[m
[31m-        int usageCount = wordData['usageCount'] as int? ?? 0;[m
[32m+[m[32m        String wordName = wordData['wordName'];[m
[32m+[m[32m        int usageCount = wordData['usageCount'] ?? 0;[m
 [m
         if (!wordMap.containsKey(wordName)) {[m
           wordMap[wordName] = {[m
             'wordName': wordName,[m
[31m-            'wordCategory': wordCategory,[m
[32m+[m[32m            'wordCategory': wordData['wordCategory'],[m
             'boardFrequencies': {},[m
             'totalUsage': 0,[m
           };[m
         }[m
 [m
         wordMap[wordName]!['boardFrequencies'][boardName] = usageCount;[m
[31m-        wordMap[wordName]!['totalUsage'] =[m
[31m-            (wordMap[wordName]!['totalUsage'] as int) + usageCount;[m
[32m+[m[32m        wordMap[wordName]!['totalUsage'] += usageCount;[m
       }[m
     }[m
 [m
[36m@@ -243,7 +234,7 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
   void _updateUniqueWordCount() {[m
     Set<String> allUniqueWords = Set<String>();[m
     for (var boardWords in _boardWords.values) {[m
[31m-      allUniqueWords.addAll(boardWords.where((word) => word != 'placeholder'));[m
[32m+[m[32m      allUniqueWords.addAll(boardWords);[m
     }[m
     _updateCounts(wordCount: allUniqueWords.length);[m
   }[m
[36m@@ -315,9 +306,9 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
 [m
   void _updateCounts([m
       {int? boardCount,[m
[31m-      int? wordCount,[m
[31m-      int? locationCount,[m
[31m-      int? activityCount}) {[m
[32m+[m[32m        int? wordCount,[m
[32m+[m[32m        int? locationCount,[m
[32m+[m[32m        int? activityCount}) {[m
     if (_isMounted) {[m
       setState(() {[m
         if (boardCount != null) _boardCount = boardCount;[m
[36m@@ -351,10 +342,10 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
           .get();[m
 [m
       QuerySnapshot<Map<String, dynamic>> guardianSnapshot =[m
[31m-          await FirebaseFirestore.instance[m
[31m-              .collection('guardian')[m
[31m-              .where('password', isEqualTo: hashedPassword)[m
[31m-              .get();[m
[32m+[m[32m      await FirebaseFirestore.instance[m
[32m+[m[32m          .collection('guardian')[m
[32m+[m[32m          .where('password', isEqualTo: hashedPassword)[m
[32m+[m[32m          .get();[m
 [m
       String userType;[m
       if (slpSnapshot.docs.isNotEmpty) {[m
[36m@@ -461,7 +452,7 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
             label,[m
             style: TextStyle([m
                 fontSize:[m
[31m-                    Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18.0,[m
[32m+[m[32m                Theme.of(context).textTheme.bodyLarge?.fontSize ?? 18.0,[m
                 fontWeight: FontWeight.bold),[m
           ),[m
         ],[m
[36m@@ -655,8 +646,7 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
 [m
     if (!userSettingsSnapshot.exists) return [];[m
 [m
[31m-    Map<String, dynamic> data =[m
[31m-        userSettingsSnapshot.data() as Map<String, dynamic>;[m
[32m+[m[32m    Map<String, dynamic> data = userSettingsSnapshot.data() as Map<String, dynamic>;[m
     Map<String, dynamic> userLocations = data['userLocations'] ?? {};[m
 [m
     List<Map<String, dynamic>> locations = [];[m
[36m@@ -761,7 +751,7 @@[m [mclass _Home_ModState extends State<Home_Mod>[m
         prefixIcon: const Icon(Icons.lock),[m
         suffixIcon: IconButton([m
           icon:[m
[31m-              Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),[m
[32m+[m[32m          Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),[m
           onPressed: () {[m
             setState(() {[m
               _passwordVisible = !_passwordVisible;[m
[36m@@ -801,14 +791,14 @@[m [mclass _WordUsageDialogState extends State<WordUsageDialog> {[m
     setState(() {[m
       _filteredWords = widget.words.where((word) {[m
         bool matchesSearch = (word['wordName'][m
[31m-                    ?.toString()[m
[31m-                    .toLowerCase()[m
[31m-                    .contains(_searchQuery.toLowerCase()) ??[m
[31m-                false) ||[m
[32m+[m[32m            ?.toString()[m
[32m+[m[32m            .toLowerCase()[m
[32m+[m[32m            .contains(_searchQuery.toLowerCase()) ??[m
[32m+[m[32m            false) ||[m
             (word['wordCategory'][m
[31m-                    ?.toString()[m
[31m-                    .toLowerCase()[m
[31m-                    .contains(_searchQuery.toLowerCase()) ??[m
[32m+[m[32m                ?.toString()[m
[32m+[m[32m                .toLowerCase()[m
[32m+[m[32m                .contains(_searchQuery.toLowerCase()) ??[m
                 false);[m
 [m
         bool matchesCategory = _selectedCategory == null ||[m
[36m@@ -818,7 +808,7 @@[m [mclass _WordUsageDialogState extends State<WordUsageDialog> {[m
         bool matchesBoard = _selectedBoard == null ||[m
             _selectedBoard == 'All' ||[m
             ((word['boardFrequencies'] as Map<dynamic, dynamic>?)[m
[31m-                    ?.containsKey(_selectedBoard) ??[m
[32m+[m[32m                ?.containsKey(_selectedBoard) ??[m
                 false);[m
 [m
         return matchesSearch && matchesCategory && matchesBoard;[m
[36m@@ -913,52 +903,52 @@[m [mclass _WordUsageDialogState extends State<WordUsageDialog> {[m
                 child: _filteredWords.isEmpty[m
                     ? Center(child: GText('No data available'))[m
                     : SingleChildScrollView([m
[31m-                        scrollDirection: Axis.vertical,[m
[31m-                        child: SingleChildScrollView([m
[31m-                          scrollDirection: