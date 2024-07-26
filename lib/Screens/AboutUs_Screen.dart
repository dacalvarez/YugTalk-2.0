import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final customPurple = isDarkMode ? Colors.deepPurple[200]! : Colors.deepPurple;
    final backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.deepPurple[50]!;
    final gradientEndColor = isDarkMode ? Colors.grey[800]! : Colors.deepPurple[100]!;

    return Scaffold(
      appBar: AppBar(
        title: GText('Our Team'),
        backgroundColor: customPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, gradientEndColor],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              GText(
                'Meet the developers behind YugTalk',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: customPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        child: DeveloperCard(
                      name: 'Lex Anilov T. Ogaya',
                      role: 'Backend Developer and Researcher',
                      bio:
                          "I'm an aspiring app developer and YugTalk will be my last, greatest test to see if I'm worthy of being one.",
                      imagePath: 'assets/images/lex_image.jpg',
                      socialLinks: [
                        {
                          'icon': 'assets/images/facebook_logo.png',
                          'url': 'https://www.facebook.com/flegs.ogaya/'
                        },
                        {
                          'icon': 'assets/images/googlesite_logo.png',
                          'url': 'https://sites.google.com/view/latogaya/home'
                        },
                      ],
                    )),
                    SizedBox(width: 24),
                    Expanded(
                        child: DeveloperCard(
                      name: 'Charles Ian S. Monteloyola',
                      role: 'Frontend Developer and Researcher',
                      bio:
                          "A future app developer with specialty in UI/UX design, YugTalk is one of my team's greatest projects.",
                      imagePath: 'assets/images/charles_image.jpg',
                      socialLinks: [
                        {
                          'icon': 'assets/images/facebook_logo.png',
                          'url': 'https://www.facebook.com/charliexecutable/'
                        },
                        {
                          'icon': 'assets/images/ig_logo.png',
                          'url': 'https://www.instagram.com/conamor_charlie/'
                        },
                        {
                          'icon': 'assets/images/googlesite_logo.png',
                          'url': 'https://sites.google.com/view/cismonteloyola/'
                        },
                        {
                          'icon': 'assets/images/linkedin_logo.png',
                          'url':
                              'https://www.linkedin.com/in/charles-ian-monteloyola-089576143/'
                        },
                      ],
                    )),
                    SizedBox(width: 24),
                    Expanded(
                        child: DeveloperCard(
                      name: 'David Anton C. Alvarez',
                      role: 'Frontend and Backend Developer and Researcher',
                      bio:
                          "6 ft 1' Filipino Aspiring to be a Cybersecurity SOC Analyst.",
                      imagePath: 'assets/images/david_image.jpg',
                      socialLinks: [
                        {
                          'icon': 'assets/images/facebook_logo.png',
                          'url':
                              'https://www.facebook.com/profile.php?id=100034694163866'
                        },
                        {
                          'icon': 'assets/images/ig_logo.png',
                          'url': 'https://www.instagram.com/dav.alvarezz'
                        },
                        {
                          'icon': 'assets/images/googlesite_logo.png',
                          'url': 'https://sites.google.com/view/dacalvarez'
                        },
                      ],
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeveloperCard extends StatelessWidget {
  final String name;
  final String role;
  final String bio;
  final String imagePath;
  final List<Map<String, String>> socialLinks;

  const DeveloperCard({
    Key? key,
    required this.name,
    required this.role,
    required this.bio,
    required this.imagePath,
    required this.socialLinks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final customPurple = isDarkMode ? Colors.deepPurple[200]! : Colors.deepPurple;
    final cardColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: customPurple, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: customPurple.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundImage: AssetImage(imagePath),
              ),
            ),
            const SizedBox(height: 24),
            GText(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: customPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: customPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: GText(
                role,
                style: TextStyle(
                  color: customPurple,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: GText(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: socialLinks
                  .map((link) => _buildSocialIcon(context, link['icon']!, link['url']!))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(BuildContext context, String iconPath, String url) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconBackgroundColor = isDarkMode ? Colors.grey[700]! : Colors.white;
    final shadowColor = isDarkMode ? Colors.black26 : Colors.deepPurple.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () => _launchURL(url),
        onHover: (hovering) {
          if (hovering) {
            HapticFeedback.lightImpact();
          }
        },
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 200),
          tween: Tween<double>(begin: 1, end: 1.1),
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      iconPath,
                      width: 34,
                      height: 34,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error,
                            color: Colors.red, size: 30);
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      print('Could not launch $url');
    }
  }
}
