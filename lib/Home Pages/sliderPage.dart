import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musicapp_/Home%20Pages/ArtistCard.dart';
import 'package:musicapp_/PlayIng%20Pages/music_play_page.dart';
import 'package:shimmer/shimmer.dart';

class CarouselSliderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerEffect();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No data available');
        } else {
          return CarouselSlider(
            options: CarouselOptions(
              autoPlay: true,
              height: 190.0,
              aspectRatio: 5.0,
              viewportFraction: 0.9,
              enlargeCenterPage: true,
              enableInfiniteScroll: true,
              autoPlayInterval: const Duration(seconds: 3),
            ),
            items: snapshot.data!.map((item) {
              String imageUrl = item['Image'] ?? '';
              String name = item['name'] ?? '';
              String colorcode = item['color'] ?? '';

              List<String> listOfMusic = (item['listOfMusic'] as List<dynamic>?)
                      ?.map((dynamic music) => music.toString())
                      .toList() ??
                  [];

              return Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () {
                      _showListOfMusic(context, imageUrl, name, colorcode,
                          listOfMusic, item);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            bottom: 8.0,
                            left: 8.0,
                            child: Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 18.0, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('TrendSongs').get();

    return querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add the document ID to the data map
      return data;
    }).toList();
  }

  void _showListOfMusic(
    BuildContext context,
    String imageUrl,
    String name,
    String colorCode,
    List<String> listOfMusic,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SliderDetailPage(
          imageUrl: imageUrl,
          name: name,
          listOfMusic: listOfMusic,
          data: data,
          colorCode: colorCode,
        );
      },
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          height: 190.0,
          aspectRatio: 5.0,
          viewportFraction: 0.9,
          enlargeCenterPage: true,
          enableInfiniteScroll: true,
          autoPlayInterval: const Duration(seconds: 3),
        ),
        items: List.generate(
          5,
          (index) => Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.0),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SliderDetailPage extends StatefulWidget {
  final String imageUrl;
  final String colorCode;
  final String name;
  final List<String> listOfMusic;
  final Map<String, dynamic> data;

  const SliderDetailPage({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.listOfMusic,
    required this.data,
    required this.colorCode,
  });

  @override
  _SliderDetailPageState createState() => _SliderDetailPageState();
}

class _SliderDetailPageState extends State<SliderDetailPage> {
  List<Map<String, dynamic>> musicDetails = [];

  @override
  void initState() {
    super.initState();
    _fetchMusicDetails();
    print('Color Code: ${widget.colorCode}');
  }

  Future<void> _fetchMusicDetails() async {
    List<Map<String, dynamic>> details = [];

    for (String musicId in widget.listOfMusic) {
      DocumentSnapshot<Map<String, dynamic>> musicSnapshot =
          await FirebaseFirestore.instance
              .collection('Music')
              .doc(musicId)
              .get();

      if (musicSnapshot.exists) {
        Map<String, dynamic> musicData = musicSnapshot.data() ?? {};
        details.add(musicData);
      }
    }

    setState(() {
      musicDetails = details;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            stops: [0.2, 1.2], // Adjust the stops as needed
            begin: Alignment.topCenter, // Adjust the starting point
            end: Alignment.bottomCenter, // Adjust the ending point
            colors: [
              Color(int.parse(widget.colorCode.substring(2), radix: 16)),
              Color(0xFF1a1b1f), // Dark background color
              // Lighter color for gradient
              // Add more color stops as needed
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200.0,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: musicDetails.isEmpty
                    ? _buildShimmerEffect()
                    : ListView.builder(
                        itemCount: musicDetails.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> musicData = musicDetails[index];
                          String documentId = widget.listOfMusic[index];
                          return ListTile(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) {
                                  return FractionallySizedBox(
                                    heightFactor:
                                        1.0, // Adjust the factor as needed
                                    child: MusicPlayPage(
                                      musicName: musicData['name'],
                                      code: widget.imageUrl,
                                      downloadUrl: musicData['file'],
                                      documentId: documentId,
                                    ),
                                  );
                                },
                              );
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF121640),
                              radius: 18,
                              child: Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            title: SizedBox(
                              width: 150,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  '${musicData['name']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            subtitle: Text(
                              widget.colorCode,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 7,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[400]!,
                shape: BoxShape.circle,
              ),
            ),
            title: Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
            ),
            subtitle: Container(
              width: 100,
              height: 16,
              margin: const EdgeInsets.only(top: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
