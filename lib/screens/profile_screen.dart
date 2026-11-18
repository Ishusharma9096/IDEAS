import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goabusconnect/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Operator and owner tools',
            onPressed: () => context.push('/roles'),
            icon: const Icon(Icons.switch_account_outlined),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EFF1)),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 39,
                    backgroundColor: Color(0xFFE4F2F3),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.primary,
                      size: 43,
                    ),
                  ),
                  SizedBox(height: 13),
                  Text(
                    'Guest Traveller',
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Sign in to personalize your experience',
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                  SizedBox(height: 17),
                  _SignInButton(),
                ],
              ),
            ),

            const SizedBox(height: 27),

            _sectionTitle('ACCOUNT'),
            const SizedBox(height: 10),

            _ProfileOption(
              icon: Icons.person_outline_rounded,
              title: 'Personal information',
              subtitle: 'Manage your account details',
            ),
            _ProfileOption(
              icon: Icons.bookmark_outline_rounded,
              title: 'Saved places',
              subtitle: 'Your favourite stops and destinations',
              route: '/stops',
            ),

            const SizedBox(height: 22),

            _sectionTitle('PREFERENCES'),
            const SizedBox(height: 10),

            _ProfileOption(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Manage travel alerts and updates',
              route: '/notifications',
            ),
            _ProfileOption(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: 'Choose your preferred language',
            ),

            const SizedBox(height: 22),

            _sectionTitle('SUPPORT'),
            const SizedBox(height: 10),

            _ProfileOption(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'Get assistance with GoaBusConnect',
            ),
            _ProfileOption(
              icon: Icons.feedback_outlined,
              title: 'Send feedback',
              subtitle: 'Share suggestions and report issues',
            ),
            _ProfileOption(
              icon: Icons.info_outline_rounded,
              title: 'About GoaBusConnect',
              subtitle: 'Learn more about the app',
              route: '/about-data',
            ),

            const SizedBox(height: 25),

            const Text(
              'GOABUSCONNECT',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'One Platform. All Buses. Better Journeys.',
              style: TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.push('/auth'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Sign In / Register',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EFF1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Icon(icon, color: AppTheme.primary, size: 23),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.muted, fontSize: 11),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppTheme.muted,
        ),
        onTap: () {
          if (route != null) {
            context.push(route!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title is not connected yet.')),
            );
          }
        },
      ),
    );
  }
}
