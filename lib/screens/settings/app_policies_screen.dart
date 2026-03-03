import 'package:flutter/material.dart';
import 'package:kidsapp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPoliciesScreen extends StatelessWidget {
  final String title;
  final String content;

  const AppPoliciesScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.fredoka(color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
      ),
    );
  }
}

class PolicyContent {
  static const String privacyPolicy = """PRIVACY POLICY - KIDOFY
Last Updated: February 2026

1. OVERVIEW
Kidofy is committed to protecting the privacy and safety of children and families. We fully comply with COPPA (Children's Online Privacy Protection Act), GDPR, CCPA, and all applicable child safety laws worldwide.

2. AGE & COPPA COMPLIANCE
- Kidofy is designed for children ages 2-17 under parental supervision
- Parents or legal guardians create and manage all accounts
- We do NOT knowingly collect personal information from children under 13 without verifiable parental consent
- Our app is COPPA-compliant with:
  * tagForChildDirectedTreatment: ENABLED
  * maxAdContentRating: PG only
  * tagForUnderAgeOfConsent: ENABLED
- Users must be at least 13 with parental notification or have parental consent if younger
- We maintain strict verification processes for parental authorization

3. WHAT INFORMATION WE COLLECT
From Parents:
- Email address and password (encrypted, stored securely)
- Payment information for premium subscriptions (processed by secure payment providers)
- Contact preferences for support communication

From Children (entered by parents):
- Child names (can be nicknames to protect identity)
- Age range or year of birth
- Content preferences and interests
- Watch history and viewing duration

From All Users:
- Device type, OS, and app version (for compatibility)
- IP address (for security and geographic content filtering)
- Crash reports and error logs (anonymized, diagnostic only)
- Basic usage analytics (pages visited, features used)
- Download history for offline content

4. HOW WE USE INFORMATION
We use collected information to:
- Deliver all app features (video streaming, recommendations, parental controls)
- Create age-appropriate recommendations for each child
- Provide parental controls and monitoring capabilities
- Prevent fraud and detect abuse
- Maintain app security and respond to security incidents
- Respond to parent support requests within 30 days
- Improve app performance and user experience
- Comply with legal obligations

We do NOT use information to:
- Create behavioral profiles for advertising
- Target personalized or behavioral ads
- Share data with third-party advertisers
- Track children across other apps or websites
- Build shadow profiles

5. ADVERTISING & DATA SAFETY

5.1 Ad Safety Standards
- Kidofy only displays kid-safe, family-friendly advertisements
- All ads are curated and reviewed for appropriateness
- Google AdMob provides our ad network with strict COPPA compliance
- Premium subscription option (ad-free) available for parents who prefer no advertisements
- NO personal data is used for ad targeting or personalization
- NO selling or sharing of user data to advertisers - ever

5.2 Ad Configuration Settings (Google AdMob COPPA Settings)
- Tag for Child-Directed Treatment: ENABLED (yes, this is child-directed content)
- Max Ad Content Rating: PG only (G and PG rated ads exclusively)
- Tag for Users Under Age of Consent: ENABLED (users under consent age flagged)
- Behavioral Targeting: DISABLED (no personalized/behavioral ads)
- Remarketing: DISABLED (no tracking across apps)
- Demographics Reporting: ENABLED (aggregate-only, no personal data)

5.3 Non-Personalized Ads
- All ads shown are non-personalized and contextual only
- Ad content is determined by topic of video, not user behavior
- No user profiling, tracking, or behavioral analysis
- Each user sees different ads based on random rotation within appropriate categories
- No cross-app tracking or data sharing with ad partners

5.4 Analytics & Crash Reporting
- Firebase analytics tracks app crashes and errors only (anonymized)
- NO personal data is sent to Firebase
- NO user profiling for analytics
- NO sharing of analytics data with advertisers
- All data encrypted in transit (HTTPS)
- Parents can opt-out of analytics by contacting support

6. DATA SHARING & THIRD PARTIES
Kidofy does NOT sell personal data under any circumstances.

We share data ONLY with these service providers who are COPPA-compliant:
- Supabase (database hosting) - for account data storage
- Google (AdMob, Firebase) - for ads and crash reporting only
- Bunny CDN (video delivery) - for video streaming
- Payment processors (Stripe, etc.) - for subscription handling only

Data sharing requirements:
- All third parties sign COPPA-compliant data processing agreements
- Data is shared only when necessary to provide the service
- Partners cannot use data for any purpose other than providing their service
- Partners cannot share data with advertisers or other third parties

We WILL share data if required by:
- Court order or legal process
- Law enforcement request (with proper authorization)
- Child safety emergencies
- Protection of Kidofy's legal rights

7. DATA SECURITY
All data is protected using:
- HTTPS/TLS encryption for all data in transit
- AES-256 encryption for data at rest
- Password hashing with bcrypt + salt (passwords never stored in plain text)
- Regular third-party security audits and penetration testing
- Employee access controls and training
- No data backups sent off-site without encryption
- Automatic logout after 30 minutes of inactivity
- Rate limiting to prevent brute force attacks

8. PARENTAL RIGHTS (COPPA & GDPR)
Parents have the following rights:

Access & Transparency:
- View all information collected about your child
- Request export of your child's data in machine-readable format
- Receive summary of data practices in child's account

Control & Deletion:
- Delete your child's account and all associated data anytime
- Restrict data collection (analytics/crash reporting can be disabled)
- Remove individual videos from watch history
- Clear all download data

Corrections:
- Correct inaccurate information
- Update child's age range or preferences
- Modify parental controls settings

Requests:
- Submit requests via email to: contact@kidofy.in
- Include valid ID and account details with requests
- We respond within 30 days (or legally required timeframe)

9. CHILDREN'S RIGHTS (COPPA & GDPR)
Parent can exercise these rights on children's behalf:
- Right to access their personal data
- Right to deletion and erasure
- Right to correction of inaccurate data
- Right to data portability (export to another service)
- No child profiling or automated decision-making

10. DATA RETENTION POLICY
- Active account data: Kept until account deletion requested
- Watch history: Kept as long as account exists (deletable per-video)
- Parental control settings: Kept as long as account exists
- Payment history: Retained per payment processor (typically 7 years for finance compliance)
- Crash/analytics logs: Anonymized, kept for 14 months maximum
- After account deletion: All data deleted within 30 days (may take 60 days for backups)

11. INTERNATIONAL COMPLIANCE
Kidofy complies with:
- U.S. COPPA (Children's Online Privacy Protection Act)
- EU GDPR (General Data Protection Regulation)
- California CCPA (California Consumer Privacy Act)
- UK Data Protection Act 2018
- Australia Privacy Act
- Canada PIPEDA
- And other child protection laws globally

11.1 INDIAN LEGAL COMPLIANCE
As an Indian-based startup, Kidofy fully complies with Indian laws:

Indian Constitution:
- Article 15: Non-discrimination (content accessible equally to all)
- Article 21: Right to life and personal liberty (data protection)
- Article 24: Prohibition of employment of children in factories (no child labor in content creation)

Information Technology Act, 2000 (IT Act):
- Section 43A: Compensation for failure to protect personal data
- Section 66E: Punishment for violation of privacy (video voyeurism, recorded private acts)
- Section 67: Punishment for publishing obscene material
- Section 67A: Punishment for publishing material depicting children in sexually explicit act
- Section 67B: Punishment for possession, distribution, of material showing children in sexual acts
- Section 72: Breach of confidentiality and privacy

Digital Personal Data Protection Act, 2023 (DPDPA):
- Complies with personal data processing principles
- Children's data classified as "sensitive personal data"
- Parental consent required for data collection from children under 18
- Right to access, correction, deletion of personal data
- Data processing agreements with all service providers
- Data localization: Sensitive data backed up in India
- Data Protection Impact Assessment (DPIA) conducted annually

Information Technology (Intermediaries Guidelines) Rules, 2021:
- Kidofy acts as intermediary, not publisher
- Content moderation code of conduct implemented
- 72-hour response to legal notices
- Grievance officer appointed for user complaints
- Registers with Ministry of Information Technology
- No hosting of illegal content
- Cooperation with law enforcement

Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011:
- Security measures: HTTPS/TLS, AES-256 encryption
- Password protection: bcrypt hashing with salt
- Access controls: Employee authentication, role-based access
- Audit logs: Maintained for 1 year minimum
- Incident response: 72-hour notification of data breach
- Privacy by design and default
- Regular security assessments

Consumer Protection Act, 2019:
- Complaint redressal: Response within 21 days
- Unfair trade practices prohibited
- Right to refund for services not rendered
- Product liability for app defects
- Consumer rights: Information, choice, safety, redressal
- Grievance mechanism available at: https://kidofy.in/complaints

Bharatiya Nyaya Sanhita, 2023 (Criminal Code):
- Section 143: Wrongfully restraining person
- Section 332-338: Causing hurt/injury
- Section 354: Insult to modesty
- Section 365-374: Kidnapping and abduction
- Section 505: Statements affecting public tranquility
- Zero tolerance for content violating these sections

Right to Information Act, 2005:
- Requests for information processed within 30 days
- Public information disclosed upon RTI request
- Personal information protected
- Contact: contact@kidofy.in

12. POLICY CHANGES
- We may update this policy with 30 days notice to parents
- Material changes require explicit parent consent
- Changes posted at: https://kidofy.in/privacy (or in-app)
- Continued use after updates = acceptance of new terms

13. CONTACT & QUESTIONS
For privacy requests, complaints, or questions:
- Email: contact@kidofy.in
- Response time: 30 days maximum
- Include your full name, child's name, and specific request

For child data requests specifically, include:
- Your full name and relationship to child
- Child's full name and account ID
- Government-issued ID copy (redacted)
- Specific request (access, deletion, correction)

For complaints about COPPA compliance:
- File with FTC at: https://reportfraud.ftc.gov
- Contact state Attorney General
- We take all privacy complaints seriously

For Indian legal complaints:
- Email: contact@kidofy.in (title: "Legal Complaint")
- Data Protection Officer: dpo@kidofy.in
- Grievance Officer: grievance@kidofy.in
- Ministry of Information Technology Complaints: https://www.meity.gov.in
- National Consumer Helpline: 1800-11-4000
- DGFT (Data Protection): dataprotection@meity.gov.in

JURISDICTION: All disputes subject to laws of India. Applicable courts: Delhi High Court.""";

  static const String termsOfService = """TERMS OF SERVICE - KIDOFY
Last Updated: February 2026

1. ACCEPTANCE OF TERMS
By downloading, installing, or using the Kidofy app, you (the parent/guardian) agree to be bound by these Terms of Service. If you do not agree, do not use this app.

2. AGE & PARENTAL RESPONSIBILITY
- This app is designed for children ages 2-17 with parental supervision
- Only parents or legal guardians may create accounts
- You are responsible for all activity on your account
- YOU are responsible for supervising your child's use of the app
- You must comply with all local laws regarding parental consent for data collection

3. ACCOUNT CREATION & VERIFICATION
- You must provide accurate, truthful email and contact information
- You are responsible for maintaining account security
- Do not share password with anyone
- Automatically logout after 30 minutes of inactivity
- Parents must verify email address before full account access
- For users under 13, parents must provide verifiable consent

4. PERMITTED USE
You agree to use Kidofy only for:
- Watching family-approved educational and entertainment videos
- Setting up and managing child profiles
- Using parental controls and monitoring tools
- Downloading content for offline viewing
- Providing feedback and reporting problems

5. PROHIBITED USE
You agree NOT to:
- Create false identities or multiple accounts to bypass age restrictions
- Share inappropriate content to the app
- Attempt to hack, bypass, or disable parental controls
- Collect data about other users
- Reverse engineer or attempt to copy the app
- Remove copyright or proprietary notices
- Use automated tools to access the app without permission
- Access the app if banned or terminated
- Share your account or password with others (except household family)

6. CONTENT & INTELLECTUAL PROPERTY
- All videos, logos, text, images, and designs are owned by Kidofy or content creators
- You may view and download for personal, non-commercial use only
- You may not copy, distribute, modify, or sell any content
- You may not use content for commercial purposes
- Content creators retain all rights to their videos
- Scraping, downloading videos without permission, or republishing is prohibited

7. PARENTAL CONTROLS & MONITORING

7.1 Your Responsibility
- Set up age-appropriate content filtering for each child
- Create PIN to protect parental settings from modification
- Regularly review watch history and content viewed
- Discuss videos and online safety with your child
- Teach your child about appropriate internet use

7.2 Available Controls
- Age range selection (Toddler 2-4, Preschool 4-6, Kids 6-12, Teens 13+)
- Block specific videos or creators
- View complete watch history
- Set screen time limits per day
- See download history
- Monitor profile activity

7.3 Age-Appropriate Content
- Toddler (2-4): Simple educational, colors, shapes, basic words, singing, counting
- Preschool (4-6): Educational, life skills, early math/reading, social-emotional learning
- Kids (6-12): Educational content matching school curriculum, STEM, arts, languages, soft entertainment
- Teens (13+): Age-appropriate learning, documentaries, how-tos, educational entertainment, soft content

8. LIMITATIONS OF LIABILITY
Kidofy is provided "as is" without warranties. We are NOT liable for:
- Technical problems or service interruptions
- Loss of data or videos
- Unauthorized access despite our security measures
- Issues with third-party services (Bunny CDN, Google, etc.)
- Any indirect, incidental, special, or consequential damages

Maximum liability is limited to subscription amount paid.

9. ACCEPTABLE USE & CONTENT STANDARDS
- You must not upload, submit, or request inappropriate content
- You must not submit content sexualizing children in any way
- You must not submit violent, hateful, or illegal content
- You must not submit spam, scams, or malware
- Violations result in immediate suspension and law enforcement notification

10. PAYMENT TERMS

Free Version:
- Free access to basic video catalog
- Family-safe ads displayed (non-personalized)
- Limited to 5 child profiles
- Standard definition streaming

Premium Versions:
- Ad-free experience
- High definition streaming
- Unlimited child profiles
- Full download library
- Advanced parental controls
- Pricing visible at point of purchase

Billing:
- Charges in local currency
- Renewed automatically at subscription end
- Refund policy: 30-day money-back guarantee if not satisfied
- Cancel anytime; you keep access until period ends
- Payment processed by secure payment provider

11. TERMINATION
Kidofy may terminate your account for:
- Violating these Terms of Service
- Repeated inappropriate behavior or content
- Hacking or attempting to bypass security
- Endangering child safety
- Non-payment (after 30-day notice)
- Inactivity (6+ months without login)

Upon termination:
- Your access ceases immediately
- Your data will be deleted within 30 days
- Refunds: Only automatic charges processed after termination notice
- Banned users cannot create new accounts

You may delete your account anytime from Settings > Account.

12. MODIFICATIONS TO TERMS
- We may update these Terms with 30 days notice
- Major changes require explicit consent
- Continued use after notice means acceptance
- Updates posted at: https://kidofy.com/terms (or in-app)

13. MODIFICATIONS TO SERVICE
- We may modify, suspend, or discontinue features
- We will provide notice for major changes
- Critical security fixes may be deployed immediately
- Continuous improvement to user experience

14. THIRD-PARTY SERVICES
Links to third-party websites (for support, policies, etc.) are provided for convenience. Kidofy is not responsible for:
- Third-party content
- Third-party privacy practices
- Third-party service availability
- Third-party security practices

You accept responsibility for reviewing third-party terms.

15. DISPUTE RESOLUTION
- Disputes will be resolved in accordance with applicable law
- Binding arbitration may be required
- Class action waivers apply
- Prevailing party may recover reasonable legal fees
- Venue: Delhi High Court, India (primary jurisdiction)
- For Indian users: Indian Arbitration and Conciliation Act, 1996
- Consumer disputes: District Consumer Commission, Delhi
- Escalation: State / National Consumer Commission

16. WARRANTIES & DISCLAIMERS
- WE MAKE NO WARRANTY THAT SERVICE IS UNINTERRUPTED OR ERROR-FREE
- WE MAKE NO WARRANTY OF SPECIFIC RESULTS
- WE MAKE NO WARRANTY OF CONTENT ACCURACY
- ALL OTHER WARRANTIES DISCLAIMED
- YOU USE THIS APP AT YOUR OWN RISK
- Parents acknowledge they have read and understood all terms
- Parents take sole responsibility for child's use of the app

17. INDIAN LEGAL COMPLIANCE
This agreement complies with:
- Information Technology Act, 2000
- Digital Personal Data Protection Act, 2023
- Information Technology (Intermediaries Guidelines) Rules, 2021
- Consumer Protection Act, 2019
- Bharatiya Nyaya Sanhita, 2023
- Indian Copyright Act, 1957
- All other applicable Indian laws

Our registered office:
Kidofy (India) Pvt. Ltd.
New Delhi, India
Email: contact@kidofy.in

Data Protection Officer:
DPO@kidofy.in
Phone: Available through in-app support
Greivance Officer appointed as per IT Rules 2021

18. SEVERABILITY
If any provision of these Terms is found invalid or unenforceable:
- That provision is modified to minimum extent to make valid
- If modification impossible, provision is severed
- Remaining provisions continue in full force
- Your rights remain unaffected where possible

18. CONTACT & SUPPORT
For questions about Terms of Service:
- Email: contact@kidofy.in
- Response time: 30 days
- Include full account details with inquiry

19. ENTIRE AGREEMENT
These Terms of Service, plus Privacy Policy and Child Safety Policy, constitute the entire agreement between you and Kidofy. Previous terms are superseded.

20. GOVERNING LAW
These Terms are governed by applicable laws where service is provided and/or where user resides. Dispute resolution follows applicable law.""";

  static const String childSafety = """CHILD SAFETY POLICY - KIDOFY
Last Updated: February 2026

COMMITMENT TO SAFETY
Kidofy is deeply committed to providing a safe, appropriate, and secure environment for children. Child safety is our highest priority. We employ multiple layers of content protection, advanced monitoring, and comprehensive parental controls.

SECTION 1: MULTI-LAYER CONTENT CURATION SYSTEM

1.1 Human Review Process
- Every video undergoes human review by trained content specialists
- Reviewers screen for: violence, profanity, sexual content, disturbing imagery, dangerous activities
- Review includes metadata, transcripts, and full video viewing when needed
- Reviewers receive COPPA compliance and child psychology training
- Content flagged as questionable undergoes second-opinion review

1.2 Age-Range Categorization
- Each video classified into appropriate age categories:
  * Toddlers (2-4): Simple, colorful, no complex plots, 0 violence
  * Preschool (4-6): Basic stories, educational focus, minimal conflict
  * Kids (6-12): Educational content, soft entertainment, no intense scenes
  * Teens (13+): Age-appropriate learning, soft entertainment, no explicit content

1.3 Creator Partnerships
- Only pre-approved educational creators and channels allowed
- Creators must sign safety agreements
- Creators prohibited from:
  * Linking to external unmoderated content
  * Requesting personal information from children
  * Promoting products to children (COPPA compliant)
  * Including dangerous activities or challenges
  * Inappropriate language or behavior modeling

1.4 Filters & Restrictions
- No social features (no comments, likes, messaging)
- No direct messaging between users
- No sharing features outside Kidofy
- No user-generated content (UGC) initially - planned with strict moderation
- No unrelated content recommendations
- No YouTube-style suggestion algorithm
- Related videos only from same safe creators

SECTION 2: PARENTAL MONITORING & CONTROLS

2.1 Watch History & Activity Tracking
Parents can view:
- Every video their child watches (title, creator, duration)
- Exactly when videos were watched (date and time)
- Total viewing time per day/week
- Most-watched creators and categories
- Viewing patterns and trends

History features:
- Delete individual videos from history
- Clear entire history for one child
- Access history for past 6 months
- Export history as CSV for discussion with child

2.2 Blocking & Restrictions
Parents can:
- Block entire creators (no videos from that creator visible)
- Block individual videos (disappears from browse and search)
- Set screen time limits per day (enforced lock-down at limit)
- Create custom content filters by educational level
- Temporarily restrict access (useful for meals, homework, sleep)
- Create device-level restrictions (app can be locked/hidden)

2.3 PIN Protection
- 4-digit PIN protects parental controls from child modification
- Parents set unique PIN
- Child cannot: change age filters, unblock content, modify limits, delete controls
- PIN changes accessible only with email verification
- PIN reset: 24-hour verification email process (prevents brute force)

2.4 Multiple Child Profiles
- Create separate profile for each child
- Each child has:
  * Personalized age range and content filters
  * Individual watch history
  * Separate screen time limits
  * Unique parental control settings
- Switch between profiles without full logout
- Parents see all profiles in dashboard

2.5 Screen Time & Usage Management
- Daily screen time limit (in minutes or hours)
- Countdown timer warns when nearing limit
- Gentle notification 15 minutes before limit
- Auto-pause when limit reached (not auto-logout)
- Weekly reset of allowance (configurable day)
- Override temporarily with parent PIN
- Reports show: total time, average per session, time of usage

2.6 Notifications & Alerts
Parents receive email/in-app notifications for:
- New content from favorite creators
- High daily viewing time (if exceeds limit)
- First-time watching of new creator
- Unknown device access (for security)
- Support messages requiring response

SECTION 3: ADVERTISING & SAFETY

3.1 Ad Standards & Protection
- NO personalized or behavioral advertising
- NO targeting ads based on watch history
- NO targeting ads based on demographics
- NO ads for age-inappropriate products
- NO fast food or sugary beverage ads to children
- NO gambling, tobacco, or alcohol ads
- NO ads pressuring children to purchase
- NO third-party data sharing for advertising

3.2 COPPA Compliance for Ads
- tagForChildDirectedTreatment: ENABLED (declared as child-directed)
- maxAdContentRating: PG only (strict rating enforcement)
- tagForUnderAgeOfConsent: ENABLED (users under 13+ flagged)
- No personalization, contextual only
- No remarketing or cross-app tracking
- No user profile building
- All ads rotated randomly from PG catalog

3.3 Ad-Free Option
- Premium subscription: Completely ad-free experience
- No behavioral ads, no tracking for ads
- Same unlimited content access
- Parental controls unchanged

3.4 In-App Purchases
- NO in-app purchases for children (disabled by default)
- Parents must explicitly enable and set spending limits
- Purchases show in activity feed for parent review
- Easy purchase reversal within 48 hours
- 7-day money-back guarantee on all purchases

SECTION 4: PRIVACY & DATA PROTECTION

4.1 Minimal Data Collection
- We collect ONLY essential data to operate the app
- NO cookies, tracking pixels, or beacons
- NO fingerprinting or device identification tracking
- NO cross-app data linking
- NO location data collection
- NO microphone or camera access requested

4.2 Data Never Shared with Advertisers
- Watch history never shared
- Profile data never shared
- Behavioral data never shared
- User IDs never shared
- Demographic data provided as aggregates only (not individual)
- Parents can opt-out of all data collection at any time

4.3 Password Security
- Passwords encrypted with bcrypt + unique salt
- Passwords never accessible to employees
- Passwords never sent in email
- Password reset via email verification link (time-limited)
- Forced password change if account suspected compromised

4.4 Account Security
- HTTPS encryption for all data transmission
- Automatic logout after 30 minutes
- Device login notifications (email to parent)
- Suspicious IP address detection
- Rate limiting prevents brute force attacks
- Employee access logs for audits

SECTION 5: REPORTING & RESPONSE PROTOCOLS

5.1 User Reporting System
- "Report Content" button on every video
- One-click reporting for inappropriate content
- Optional message box for details
- Reports anonymous and confidential
- Child can report without parental assistance
- Alternative: Parents report via Settings > Report Problem

5.2 Response Protocols
Upon report submission:
- Automated acknowledgment sent to reporter
- Reports reviewed within 24 hours
- Content may be immediately removed if severe (violence, abuse)
- Cases involving child exploitation reported to NCMEC (National Center for Missing & Exploited Children)
- If creator violation found: creator content removed and creator banned
- Minor violations: warning sent to creator
- Reporter notified of outcome (within 72 hours)

5.3 Escalation Procedures
- Reports of violence: Reviewed within 1 hour
- Reports involving children in danger: Immediate removal + law enforcement notification
- Reports of content encouraging self-harm: Removed + resources provided to parent
- Requests for creator content removal: Reviewed within 24 hours
- Emergency safety issues: Dedicated support line available

5.4 Appeals Process
- Creators may appeal removal decisions within 10 days
- Parents may appeal block decisions
- Appeals reviewed by senior safety team within 72 hours
- Decision communicated with explanation
- Final appeal to safety ombudsman possible

SECTION 6: CREATOR MODERATION & SUSPENSIONS

6.1 Creator Standards
All creators must:
- Be at least 18 years old
- Comply with COPPA requirements
- Not collect personal information from viewers
- Not promote unsafe activities or challenges
- Maintain consistent quality and appropriateness
- Not monetize exclusively through Kidofy (avoid dependency)

6.2 Creator Verification
- Identity verification required
- Background check for channels with direct audience
- Tax/payment information verified
- Ongoing monitoring of upload compliance

6.3 Suspension & Banning
Creator receives warning for:
- First minor violation (e.g., occasional profanity)
- Inappropriate comment interaction
- Educational quality issues
- Copyright claims (resolved within 7 days)

Creator suspended (channel hidden from app) for:
- Repeated violations after warnings
- Requesting personal information
- Selling products to children
- Encouraging dangerous behavior
- Harassment or bulk reporting retaliation

Creator permanently banned for:
- Content sexualizing minors (zero-tolerance)
- Child endangerment or exploitation
- Illegal activity
- Hate speech or discrimination
- Repeated suspensions without improvement

6.4 Creator Communications
- Creators notified of violations with specific examples
- Given opportunity to remove problematic content
- Appeals process available within 15 days
- Banned creators receive detailed explanation
- List of safe creators publicly available to parents

SECTION 7: SPECIAL SAFETY CONSIDERATIONS

7.1 Stranger Danger
- NO private messaging between users
- NO direct contact information shared
- NO user profiles visible to other users
- NO following/friending system
- NO comment sections where strangers interact
- NO social features whatsoever
- App is consumption-only, not social
- Any suspicious behavior reported to authorities

7.2 Cyberbullying Prevention
- No user-to-user interaction (eliminates cyberbullying platform)
- Parents teach offline about healthy online interaction
- Report button available for any content making child uncomfortable
- Community standards prohibit harassment

7.3 Self-Harm & Mental Health
- No content promoting self-harm, suicide, or eating disorders
- Content discussing mental health must be from qualified professionals
- Parent resources and hotlines provided:
  * National Suicide Prevention Lifeline: 988
  * Crisis Text Line: Text HOME to 741741
- Content showing concerning themes flagged with parent notification
- Links to mental health resources provided to parents

7.4 Dangerous Content & Challenges
- Zero-tolerance policy for dangerous challenges or activities
- Content showing risky behavior includes parental warning
- Dares, stunts, or activities endangering children prohibited
- Falls, accidents, or injury content restricted
- Parent receives alert if child watches concerning content

7.5 Religious & Cultural Sensitivity
- Content respects diverse beliefs and cultures
- No promotion of prejudice or discrimination
- Content may discuss different religions without bias
- Parents can filter by cultural appropriateness if desired
- Community feedback considered for borderline content

SECTION 8: PARENTAL GUIDANCE & RESOURCES

8.1 Recommended Parental Actions

Weekly:
- Review watch history (15 minutes)
- Discuss videos watched (5-10 minutes conversation)
- Check screen time totals
- Notice any new creators or unusual activity

Monthly:
- Full content review (scan new category choices)
- Update parental controls if child's interests changed
- Discuss internet safety rules
- Review any reported content

Quarterly:
- Full account audit
- Discuss digital citizenship
- Update age filters if child's developmental stage changed
- Review parental control effectiveness

8.2 Age-Appropriate Conversations
For Toddlers (2-4):
- "Tell me about what you watched today"
- "Did you like the colors/music?"
- "What did you learn?" (validate learning)

For Preschoolers (4-6):
- "Who were the characters in that video?"
- "What was the video teaching us?"
- "Would you do that activity in real life?"
- Introduce basic safety rules

For Kids (6-12):
- Deeper discussion of content themes
- "What was the message of that video?"
- Introduce digital citizenship (privacy, not sharing info)
- Discuss advertising and marketing
- Teach critical thinking about media

For Teens (13+):
- Discuss media literacy and bias
- Media ownership and profit motives
- Healthy screen time importance
- Online predator awareness
- Digital reputation and footprint

8.3 Screen Time Best Practices
- American Academy of Pediatrics (AAP) recommends:
  * Ages 2-5: Maximum 1 hour quality content daily, co-view when possible
  * Ages 6+: Consistent limits ensuring screen time doesn't interfere with sleep, exercise, other healthy habits
  * Avoid screens 1 hour before bedtime
  * No screens during meals
  * Device-free zones (bedrooms, bathrooms)

Kidofy Features Supporting Best Practices:
- Daily limits with reminders
- Co-viewing recommendations
- Educational content badges
- Screen time reports

8.4 Resources for Parents
- Free online safety guides at: https://kidofy.com/parenting
- Digital parenting webinars (monthly, free)
- Email support: contact@kidofy.in
- Community forum to discuss with other parents
- Links to organizations:
  * Common Sense Media parenting advice
  * Family Online Safety Institute resources
  * National Center for Missing & Exploited Children safety tips

SECTION 9: LEGAL COMPLIANCE & ENFORCEMENT

9.1 Law Enforcement & Child Safety
We cooperate fully with law enforcement to protect children:
- NCMEC CyberTipline: Child exploitation reports sent automatically
- Law enforcement requests: Document preserved, disclosed per legal process
- Child endangerment: Immediate account suspension + authorities notification
- Evidence preservation: Account frozen for potential investigation
- Subpoena response: Within 20 business days (or as legally required)

For Indian law enforcement:
- cooperation with CBI (Central Bureau of Investigation) as required
- Compliance with National Cybercrime Reporting Portal (NCRP)
- Cooperation with State Police (Cyber Cells)
- Response to legal notices under Information Technology Act, 2000 within 72 hours
- Compliance with Bharatiya Nyaya Sanhita, 2023 sections on child safety

9.2 Abuse & Exploitation
Zero-tolerance for any content, request, or behavior involving:
- Sexual exploitation or abuse of minors
- Child trafficking or grooming
- Illegal activity involving children
- Manufacturing or distributing CSAM (child sexual abuse material)

All such reports immediately referred to:
- National Center for Missing & Exploited Children (NCMEC) / Indian equivalent
- FBI ICT or local law enforcement
- Indian Cybercrime Coordination Centre (I4C) - Ministry of Home Affairs
- National Crime Records Bureau (NCRB)
- State Cybercrime Police Units
- Email reports can be made by anyone

9.3 Indian Content Rating Standards (IBFC)
Kidofy uses content classification compliant with Indian Board of Film Certification (IBFC):
- U (Unrestricted): For general audiences, all ages (Toddler 2-4, Preschool 4-6)
- UA (Unrestricted-Adult): Parental discretion for children below 12 (Kids 6-12)
- A (Restricted): Only for adults, 18+ (not available in Kidofy)
- S (Restricted): Specialized, technical audiences only (not available in Kidofy)

Kidofy maintains U and UA content only. No A or S rated content.

9.4 Indian Legal Compliance for Content
- Section 67 IT Act: No obscene material
- Section 67A IT Act: No child sexual abuse material
- Section 67B IT Act: No child pornography
- Cinematograph Act, 1952: Content follows IBFC classification
- Cable Television Networks (Regulation) Act, 1995: Family-safe hours compliance
- Indian Copyright Act, 1957: All content properly licensed

Content Review:
- Every uploaded content checked for compliance within 24 hours
- Violating content removed immediately
- Creator banned for IP violations
- Law enforcement notified for criminal content

9.5 International Compliance
Kidofy complies with child protection laws globally:
- U.S.: COPPA (Federal Trade Commission enforcement)
- EU: GDPR (child protection articles)
- UK: Data Protection Act 2018, Online Safety Bill
- Canada: PIPEDA (privacy regulations)
- Australia: Privacy Act & eSafety Commissioner
- India: All acts mentioned above

SECTION 10: CONTINUOUS IMPROVEMENT

10.1 Safety Monitoring
- Full video catalog re-reviewed quarterly
- New content reviewed before app visibility
- Automated flagging of concerning patterns
- Monthly safety metrics review by safety team
- Quarterly third-party safety audits

10.2 Parent & Child Feedback
- Safety feedback form in-app
- Monthly safety survey for parents
- Child comfort feedback (anonymous)
- Reviews incorporated into content decisions
- Public safety report published semi-annually

10.3 Policy Updates
- Policy reviewed annually or sooner if needed
- Updates communicated 30+ days in advance
- Version history maintained for transparency
- Community input requested for major changes
- Parents can subscribe to policy update notifications

SECTION 11: INDIAN LEGAL COMPLIANCE & CHILD PROTECTION

11.1 Constitutional Protection
Kidofy respects and implements principles from Indian Constitution:
- Article 15: No discrimination in content access (all children treated equally)
- Article 21: Right to life and personal liberty (data and privacy protection)
- Article 24: Prevention of child labor (no exploitative content creation)
- Article 39(f): Safeguarding against moral and material abandonment of children

11.2 Information Technology Act, 2000 Compliance
- Section 66E: No obscene, voyeuristic content involving children
- Section 67: Zero obscene material - U/UA IBFC rating only
- Section 67A: Zero child sexual abuse material (CSAM) - ZERO TOLERANCE
- Section 67B: Zero child pornography - automatic law enforcement referral
- Section 69: Decryption cooperation with government authorities
- Section 72: Breach of confidentiality penalties for employees (training mandatory)

All employees sign confidentiality agreements with ITES Act 2000 Section 72 penalties.

11.3 Digital Personal Data Protection Act, 2023 (DPDPA)
- Children's data: Classified as \"sensitive personal data\"
- Parental consent: Required for all data collection from users under 18
- Processing principles: Lawful, fair, transparent (Kidofy meets all)
- Consent withdrawal: Parents can withdraw anytime (data deleted within 30 days)
- Data Access Officer (DAO): Appointed for children's data requests
- Data Protection Impact Assessment (DPIA): Conducted annually, on file

Children's Data Localization:
- Sensitive personal data backed up in India (Supabase India region)
- No sending children's data to foreign servers without explicit parental consent
- Cross-border data transfers: Only when legally required (court order, etc.)
- All foreign partners (Google, Bunny) have DPDPA-compliant agreements

11.4 Information Technology (Intermediaries Guidelines) Rules, 2021
Kidofy's Intermediary Obligations:
- Content Moderation Code: Published and enforced
- Grievance Procedure: Within 5 days of report
- Grievance Officer: Appointed (grievance@kidofy.in)
- Chief Compliance Officer: Appointed (compliance@kidofy.in)
- Registration: With Ministry of Information Technology
- Blocking Procedure: Comply with Section 69A notices within 36 hours
- Preservation: Evidence kept for 180 days maximum as required
- Report to MeitY: Quarterly compliance reports filed

Government Notice Response:
- 72-hour response to legal notices
- Removal of flagged content within timeframe
- Preservation of user data for investigation
- Cooperation with law enforcement

11.5 Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011
- Security Policy: Document maintained and updated quarterly
- Audit logs: Kept for 90 days minimum (exceeds 30-day requirement)
- Access control: Role-based, least privilege principle
- Encryption: HTTPS + AES-256 (exceeds minimum)
- Network security: Firewalls, DDoS protection, intrusion detection
- Incident response: 72-hour notification of data breach to affected users and authorities
- Annual security assessment: Third-party audit conducted
- Employee training: Annual data protection training for all staff
- Data breach notification: Email + in-app notification within 72 hours

11.6 Consumer Protection Act, 2019 (CPA 2019)
- Consumer Rights: Information, choice, safety, redressal (all guaranteed)
- Complaint Redressal Mechanism: Response within 21 days required
- Unfair Trade Practices: Prohibited, Kidofy maintains ethical standards
- Advertisements: Accurate, no misleading claims about safety features
- Product Liability: Kidofy liable for defects causing injury/damage
- Refund Policy: 30-day money-back guarantee for premium subscriptions
- District Consumer Commission: Jurisdiction for consumer disputes
- Grievance: Available at https://kidofy.com/complaints or grievance@kidofy.in

Parental Consumer Rights:
- Right to be informed: Complete policy transparency
- Right to choose: Age filters, content controls, cancellation anytime
- Right to be heard: Grievance officers listen to complaints
- Right to satisfaction: Issues resolved within 21 days
- Right to safety: Data protection, content safety standards

11.7 Bharatiya Nyaya Sanhita, 2023 (Criminal Code)
Content Prohibited Under BNS:
- Section 74: Abeting commission of offence (no content encouraging crime)
- Section 143: Wrongful restraint (no kidnapping/abduction content)
- Section 324-338: Criminal intimidation / causing hurt / grievous injury / assault (no violence)
- Section 354: Disrobing / exposing private parts to insult modesty (zero tolerance)
- Section 365-374: Kidnapping / abduction / hostage for ransom (zero tolerance)
- Section 376: Sexual assault (zero tolerance, automatic law enforcement)
- Section 505: Statements creating fear / enmity / communal disharmony (prohibited)
- Section 509: Obscene acts / words / sounds / gestures (prohibited)

All violating content removed within 24 hours, creator banned, police notified.

11.8 Right to Information Act (RTI), 2005
- Public information requests: Processed within 30 days
- Proactive disclosure: Safety reports published semi-annually
- Privacy protection: Personal data not disclosed under RTI
- RTI Officer: dpo@kidofy.in for information requests

11.9 RBI Guidelines for Online Payments
- All payment processing: Compliant with Reserve Bank of India (RBI) guidelines
- PCI-DSS Compliance: Payment Card Industry Data Security Standard
- Transaction Security: SSL/TLS encryption for all payment flows
- Refund Process: Initiated within 5 business days
- Dispute Resolution: Per RBI Ombudsman scheme
- Two-Factor Authentication: Available for parent accounts

11.10 Indian Copyright Act, 1957
- All content: Properly licensed or created by creators
- Creator Rights: Respected and protected
- Copyright Verification: Part of onboarding for all creators
- Infringement Process: DMCA-equivalent takedown within 24 hours
- Creator Support: Legal team assists with copyright issues

SECTION 12: DECLARATION

Kidofy pledges to:
- Always prioritize child safety above business interests
- Maintain the highest standards of age-appropriate content
- Provide parents with powerful, easy-to-use controls
- Operate with transparency and accountability
- Respond swiftly to safety concerns
- Continuously innovate safety technologies
- Comply with all child protection laws globally, especially Indian laws
- Invest significant resources in safety infrastructure
- Treat every report seriously and investigate thoroughly
- Support healthy child development through responsible media
- Protect Indian children with highest standards
- Maintain compliance with Indian Constitution and all acts

Kidofy will NEVER:
- Exploit child data for profit
- Allow inappropriate content
- Ignore safety reports
- Compromise child safety for business
- Share data with dangerous third parties
- Enable child exploitation
- Violate Section 67A/67B of IT Act (child sexual abuse material)
- Violate Indian Copyright Act or intellectual property rights
- Exploit child labor in content creation
- Engage in unfair trade practices

INDIA-SPECIFIC COMMITMENT:
- Registered as: Kidofy (India) Pvt. Ltd., New Delhi
- Governed by: Laws of India, jurisdiction Delhi High Court
- Compliance Officer: Appointed under IT (Intermediaries) Rules 2021
- Data Protection Officer: Appointed, responds to DPA requests
- Grievance Officer: Appointed, resolves complaints within 5 days
- Quarterly compliance reports: Filed with Ministry of IT

QUESTIONS OR CONCERNS?
- Email: contact@kidofy.in
- Safety hotline: Available through in-app support
- Anonymous report form: Settings > Report Problem
- Grievance Officer: grievance@kidofy.in
- Data Protection Officer: dpo@kidofy.in
- Compliance Officer: compliance@kidofy.in
- Legal Address: New Delhi, India
- Phone: Available through in-app support

For Indian law enforcement / government:
- Ministry of Information Technology: https://www.meity.gov.in
- Cybercrime Portal: https://cybercrime.gov.in
- File complaint: cybercrime@delhi.gov.in
- National Consumer Helpline: 1800-11-4000""";
}
