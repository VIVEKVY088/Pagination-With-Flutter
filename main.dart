import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer package

void main() => runApp(MaterialApp(
  home: HomePage(),
));

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final scrollController = ScrollController();
  bool isLoadingMore = false;
  bool isLoadingTop = false;

  List posts = [];
  int page = 1;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    fetchPosts(); // Initial posts fetch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(12.0),
        controller: scrollController,
        itemCount: (isLoadingMore || isLoadingTop) ? posts.length + 1 : posts.length,
        itemBuilder: (context, index) {
          if (index < posts.length) {
            final post = posts[index];
            final title = post['title']['rendered'];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text('$title'),

              ),
            );
          } else {
            // Show shimmer effect while loading
            return _buildShimmer();
          }
        },
      ),
    );
  }

  Future<void> fetchPosts() async {
    final url = 'https://techcrunch.com/wp-json/wp/v2/posts?context=embed&per_page=15&page=$page';
    print('$url');
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List;

      setState(() {
        if (isLoadingTop) {
          // If we are scrolling up, insert posts at the top
          posts.insertAll(0, json);
        } else {
          // Else add to the bottom
          posts.addAll(json);
        }
      });
    } else {
      print('Unexpected response');
    }
  }

  Future<void> _scrollListener() async {
    if (isLoadingMore || isLoadingTop) return; // Avoid triggering multiple requests

    // Detect if the user is scrolling down to load more
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      setState(() {
        isLoadingMore = true;  // Start loading more posts
      });
      page++;
      await fetchPosts();
      setState(() {
        isLoadingMore = false; // End loading more posts
      });
    }

    // Detect if the user is scrolling up to load older posts
    if (scrollController.position.pixels == scrollController.position.minScrollExtent) {
      if (page > 1) { // Only allow scrolling up if page > 1
        setState(() {
          isLoadingTop = true; // Start loading older posts
        });
        page--;  // Decrement the page to load older posts
        await fetchPosts();
        setState(() {
          isLoadingTop = false; // End loading older posts
        });
      }
    }
  }

  // Function to build shimmer effect for loading items
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade400,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(5, (index) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
              ),
              title: Container(
                width: 150,
                height: 15,
                color: Colors.grey.shade300,
              ),
              subtitle: Container(
                width: 100,
                height: 10,
                color: Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
    );
  }
}







