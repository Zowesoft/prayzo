import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/sample_data.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/scripture_reference_card.dart';
import '../widgets/upcoming_prayer_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showFloatingButton) {
      setState(() {
        _showFloatingButton = true;
      });
    } else if (_scrollController.offset <= 200 && _showFloatingButton) {
      setState(() {
        _showFloatingButton = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPrayer = SampleData.prayers.first;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text('PrayerVerse'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.lightBlue,
            child: Icon(Icons.person, size: 20, color: AppColors.primaryBlue),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(seconds: 1));
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Video Player Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: VideoPlayerWidget(
                  title: currentPrayer.title,
                  author: currentPrayer.author,
                  isLive: currentPrayer.isLive,
                ),
              ),
            ),

            // Scripture References
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: currentPrayer.scriptureReferences.length,
                  itemBuilder: (context, index) {
                    return ScriptureReferenceCard(
                      reference: currentPrayer.scriptureReferences[index],
                    );
                  },
                ),
              ),
            ),

            // Engagement Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.red, size: 20),
                        SizedBox(width: 4),
                        Text('${currentPrayer.likes}', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    SizedBox(width: 24),
                    Row(
                      children: [
                        Icon(Icons.comment_outlined, color: AppColors.grey, size: 20),
                        SizedBox(width: 4),
                        Text('${currentPrayer.comments}', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Spacer(),
                    Icon(Icons.share_outlined, color: AppColors.grey, size: 20),
                  ],
                ),
              ),
            ),

            // Upcoming Prayers Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Upcoming Prayers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return UpcomingPrayerCard(
                    event: SampleData.upcomingEvents[index],
                  );
                },
                childCount: SampleData.upcomingEvents.length,
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _showFloatingButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.primaryBlue,
              child: Icon(Icons.keyboard_arrow_up, color: Colors.white),
            )
          : null,
    );
  }
}