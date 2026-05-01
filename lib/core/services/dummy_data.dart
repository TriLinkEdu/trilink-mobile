class DummyData {
  DummyData._();

  // ─── Auth / User ──────────────────────────────────────
  static Map<String, dynamic> get teacherUser => {
        'id': 'teacher-001',
        'email': 'sara.ahmed@school.edu',
        'role': 'teacher',
        'firstName': 'Sara',
        'lastName': 'Ahmed',
        'phone': '+251911234567',
        'subject': 'Mathematics',
        'department': 'Science',
        'mustChangePassword': false,
        'createdAt': '2025-09-01T08:00:00Z',
      };

  static Map<String, dynamic> get parentUser => {
        'id': 'parent-001',
        'email': 'mohammed.hassan@email.com',
        'role': 'parent',
        'firstName': 'Mohammed',
        'lastName': 'Hassan',
        'phone': '+251933456789',
        'childName': 'Ali Hassan',
        'relationship': 'Father',
        'mustChangePassword': false,
        'createdAt': '2025-09-01T08:00:00Z',
      };

  // ─── Dashboard ────────────────────────────────────────
  static Map<String, dynamic> get teacherDashboard => {
        'myClasses': 5,
        'pendingGradingApprox': 14,
        'unreadNotifications': 3,
      };

  static Map<String, dynamic> get parentDashboard => {
        'linkedChildren': [
          {
            'id': 'stu-001',
            'studentId': 'stu-001',
            'firstName': 'Ali',
            'lastName': 'Hassan',
            'fullName': 'Ali Hassan',
            'grade': 'Grade 9',
            'section': 'A',
            'avatar': '',
          },
          {
            'id': 'stu-010',
            'studentId': 'stu-010',
            'firstName': 'Leila',
            'lastName': 'Hassan',
            'fullName': 'Leila Hassan',
            'grade': 'Grade 7',
            'section': 'B',
            'avatar': '',
          },
        ],
        'unreadNotifications': 5,
      };

  static Map<String, dynamic> childSummary(String studentId) => {
        'activeEnrollments': 6,
        'unreadNotifications': 2,
        'studentId': studentId,
        'average': '87',
        'avgDelta': '+3.2% this week',
        'attendance': '94',
        'absences': '3 absences',
        'pendingTasks': '4',
        'recentActivity': [
          {
            'type': 'grade',
            'title': 'Math Quiz',
            'description': 'Scored 92% on Algebra Quiz',
            'date': '2026-03-28',
          },
          {
            'type': 'attendance',
            'title': 'Attendance',
            'description': 'Present - all classes',
            'date': '2026-03-27',
          },
          {
            'type': 'assignment',
            'title': 'Science Homework',
            'description': 'Submitted Chapter 5 worksheet',
            'date': '2026-03-26',
          },
        ],
      };

  static Map<String, dynamic> childDashboard(String studentId) => {
        'student': {
          'id': studentId,
          'firstName': 'Ali',
          'lastName': 'Hassan',
          'email': 'ali@school.edu',
        },
        'grades': {
          'overallAveragePercent': 84.5,
          'bySubject': [
            {'subjectId': 'sub-001', 'subjectName': 'Mathematics', 'gradedEntries': 5, 'averagePercent': 88.0},
            {'subjectId': 'sub-002', 'subjectName': 'Physics', 'gradedEntries': 3, 'averagePercent': 82.0},
            {'subjectId': 'sub-003', 'subjectName': 'Chemistry', 'gradedEntries': 4, 'averagePercent': 79.5},
          ],
        },
        'attendance': {
          'overall': {
            'total': 60,
            'present': 54,
            'absent': 4,
            'excused': 2,
            'attendancePercent': 90.0,
          },
          'bySubject': [
            {'subjectId': 'sub-001', 'subjectName': 'Mathematics', 'total': 20, 'present': 19, 'absent': 1, 'excused': 0, 'attendancePercent': 95.0},
            {'subjectId': 'sub-002', 'subjectName': 'Physics', 'total': 20, 'present': 17, 'absent': 2, 'excused': 1, 'attendancePercent': 85.0},
            {'subjectId': 'sub-003', 'subjectName': 'Chemistry', 'total': 20, 'present': 18, 'absent': 1, 'excused': 1, 'attendancePercent': 90.0},
          ],
        },
        'upcoming': {
          'exams': [
            {
              'id': 'exam-001',
              'title': 'Biology Midterm',
              'opensAt': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
              'closesAt': DateTime.now().add(const Duration(days: 3, hours: 2)).toIso8601String(),
              'maxPoints': 100,
              'status': 'upcoming',
              'score': null,
            },
          ],
          'assignments': [
            {
              'id': 'asgn-001',
              'title': 'Chapter 3 Worksheet',
              'deadline': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
              'maxScore': 50,
              'status': 'pending',
              'score': null,
            },
          ],
          'summary': {
            'examsTotal': 1,
            'examsAvailable': 0,
            'assignmentsTotal': 1,
            'assignmentsPending': 1,
          },
        },
      };

  // ─── Academic Year ────────────────────────────────────
  static Map<String, dynamic> get activeAcademicYear => {
        'id': 'ay-001',
        'name': '2025/2026',
        'startDate': '2025-09-01',
        'endDate': '2026-06-30',
        'status': 'active',
      };

  // ─── Class Offerings ─────────────────────────────────
  static List<dynamic> get classOfferings => [
        {
          'id': 'co-001',
          'grade': {'id': 'g-001', 'name': 'Grade 9'},
          'section': {'id': 's-001', 'name': 'A'},
          'subject': {'id': 'sub-001', 'name': 'Mathematics'},
          'teacher': {'id': 'teacher-001', 'firstName': 'Sara', 'lastName': 'Ahmed'},
          'academicYearId': 'ay-001',
          'studentCount': 32,
        },
        {
          'id': 'co-002',
          'grade': {'id': 'g-001', 'name': 'Grade 9'},
          'section': {'id': 's-002', 'name': 'B'},
          'subject': {'id': 'sub-001', 'name': 'Mathematics'},
          'teacher': {'id': 'teacher-001', 'firstName': 'Sara', 'lastName': 'Ahmed'},
          'academicYearId': 'ay-001',
          'studentCount': 28,
        },
        {
          'id': 'co-003',
          'grade': {'id': 'g-002', 'name': 'Grade 10'},
          'section': {'id': 's-001', 'name': 'A'},
          'subject': {'id': 'sub-002', 'name': 'Physics'},
          'teacher': {'id': 'teacher-001', 'firstName': 'Sara', 'lastName': 'Ahmed'},
          'academicYearId': 'ay-001',
          'studentCount': 25,
        },
        {
          'id': 'co-004',
          'grade': {'id': 'g-002', 'name': 'Grade 10'},
          'section': {'id': 's-002', 'name': 'B'},
          'subject': {'id': 'sub-003', 'name': 'Chemistry'},
          'teacher': {'id': 'teacher-001', 'firstName': 'Sara', 'lastName': 'Ahmed'},
          'academicYearId': 'ay-001',
          'studentCount': 30,
        },
        {
          'id': 'co-005',
          'grade': {'id': 'g-003', 'name': 'Grade 11'},
          'section': {'id': 's-001', 'name': 'A'},
          'subject': {'id': 'sub-001', 'name': 'Mathematics'},
          'teacher': {'id': 'teacher-001', 'firstName': 'Sara', 'lastName': 'Ahmed'},
          'academicYearId': 'ay-001',
          'studentCount': 22,
        },
      ];

  // ─── Attendance ───────────────────────────────────────
  static List<dynamic> attendanceSessions(String classOfferingId) => [
        {
          'id': 'as-001',
          'classOfferingId': classOfferingId,
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'as-002',
          'classOfferingId': classOfferingId,
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
      ];

  static List<dynamic> get attendanceMarks => [
        {'studentId': 'stu-001', 'studentName': 'Ali Hassan', 'status': 'present'},
        {'studentId': 'stu-002', 'studentName': 'Fatima Abdi', 'status': 'present'},
        {'studentId': 'stu-003', 'studentName': 'Yusuf Omar', 'status': 'absent'},
        {'studentId': 'stu-004', 'studentName': 'Amina Bekele', 'status': 'present'},
        {'studentId': 'stu-005', 'studentName': 'Daniel Tadesse', 'status': 'late'},
        {'studentId': 'stu-006', 'studentName': 'Hana Girma', 'status': 'present'},
        {'studentId': 'stu-007', 'studentName': 'Samuel Kebede', 'status': 'present'},
        {'studentId': 'stu-008', 'studentName': 'Meron Tesfaye', 'status': 'absent'},
      ];

  static Map<String, dynamic> get classAttendanceReport => {
        'averageAttendance': 92.5,
        'totalAbsences': 18,
        'lateArrivals': 7,
        'weeklyTrend': [
          {'week': 'Week 1', 'attendance': 95.0},
          {'week': 'Week 2', 'attendance': 91.0},
          {'week': 'Week 3', 'attendance': 88.0},
          {'week': 'Week 4', 'attendance': 93.0},
          {'week': 'Week 5', 'attendance': 96.0},
        ],
        'mostAbsentStudents': [
          {'studentName': 'Yusuf Omar', 'absences': 5},
          {'studentName': 'Meron Tesfaye', 'absences': 4},
          {'studentName': 'Daniel Tadesse', 'absences': 3},
        ],
        'dailyBreakdown': [
          {'day': 'Mon', 'present': 28, 'absent': 2, 'late': 1},
          {'day': 'Tue', 'present': 30, 'absent': 1, 'late': 0},
          {'day': 'Wed', 'present': 27, 'absent': 3, 'late': 2},
          {'day': 'Thu', 'present': 29, 'absent': 2, 'late': 0},
          {'day': 'Fri', 'present': 26, 'absent': 4, 'late': 1},
        ],
      };

  static Map<String, dynamic> studentAttendanceReport(String studentId) => {
        'studentId': studentId,
        'attendanceRate': '95',
        'totalAbsences': '3',
        'lateArrivals': '2',
        'termLabel': 'Term 2 Overview',
        'termDates': 'Jan 2026 – Mar 2026',
        'subjects': ['Mathematics', 'Physics', 'Chemistry', 'English', 'History'],
        'records': [
          {'date': '2026-03-03', 'status': 'present'},
          {'date': '2026-03-04', 'status': 'present'},
          {'date': '2026-03-05', 'status': 'present'},
          {'date': '2026-03-06', 'status': 'late'},
          {'date': '2026-03-07', 'status': 'present'},
          {'date': '2026-03-10', 'status': 'present'},
          {'date': '2026-03-11', 'status': 'absent'},
          {'date': '2026-03-12', 'status': 'present'},
          {'date': '2026-03-13', 'status': 'present'},
          {'date': '2026-03-14', 'status': 'present'},
          {'date': '2026-03-17', 'status': 'present'},
          {'date': '2026-03-18', 'status': 'present'},
          {'date': '2026-03-19', 'status': 'absent'},
          {'date': '2026-03-20', 'status': 'present'},
          {'date': '2026-03-21', 'status': 'present'},
          {'date': '2026-03-24', 'status': 'present'},
          {'date': '2026-03-25', 'status': 'late'},
          {'date': '2026-03-26', 'status': 'present'},
          {'date': '2026-03-27', 'status': 'present'},
          {'date': '2026-03-28', 'status': 'absent'},
          {'date': '2026-03-31', 'status': 'present'},
        ],
        'recentActivity': [
          {'date': '2026-03-28', 'status': 'Absent', 'subjects': 'All subjects'},
          {'date': '2026-03-25', 'status': 'Late Arrival', 'subjects': 'Math, Physics'},
          {'date': '2026-03-19', 'status': 'Absent', 'subjects': 'All subjects'},
          {'date': '2026-03-11', 'status': 'Absent', 'subjects': 'All subjects'},
          {'date': '2026-03-06', 'status': 'Late Arrival', 'subjects': 'English'},
        ],
      };

  static Map<String, dynamic> get studentAttendanceByDay => {
        'studentId': 'stu-001',
        'firstName': 'Ali',
        'lastName': 'Hassan',
        'email': 'ali@school.edu',
        'grade': 'Grade 9',
        'section': 'A',
        'date': '2026-04-22',
        'records': [
          {
            'markId': 'mark-001',
            'status': 'present',
            'note': null,
            'sessionId': 'session-001',
            'classOfferingId': 'co-001',
            'className': 'Math 9A',
            'subject': {'id': 'subj-001', 'name': 'Mathematics', 'code': 'MATH'},
            'grade': {'id': 'grade-001', 'name': 'Grade 9'},
            'section': {'id': 'sec-001', 'name': 'A'},
            'teacher': {
              'id': 'teacher-001',
              'firstName': 'Jane',
              'lastName': 'Doe',
              'email': 'jane@school.edu',
              'department': 'Science',
              'officeRoom': '101'
            },
          },
          {
            'markId': 'mark-002',
            'status': 'late',
            'note': 'Arrived 10 minutes late',
            'sessionId': 'session-002',
            'classOfferingId': 'co-002',
            'className': 'Physics 9A',
            'subject': {'id': 'subj-002', 'name': 'Physics', 'code': 'PHYS'},
            'grade': {'id': 'grade-001', 'name': 'Grade 9'},
            'section': {'id': 'sec-001', 'name': 'A'},
            'teacher': {
              'id': 'teacher-002',
              'firstName': 'John',
              'lastName': 'Smith',
              'email': 'john@school.edu',
              'department': 'Science',
              'officeRoom': '102'
            },
          },
        ],
      };

  // ─── Calendar Events ──────────────────────────────────
  static List<dynamic> get calendarEvents => [
        {
          'id': 'evt-001',
          'title': 'Math Midterm Exam',
          'type': 'exam',
          'startDate': '2026-04-05T09:00:00Z',
          'endDate': '2026-04-05T11:00:00Z',
          'location': 'Room 201',
        },
        {
          'id': 'evt-002',
          'title': 'Parent-Teacher Conference',
          'type': 'meeting',
          'startDate': '2026-04-10T14:00:00Z',
          'endDate': '2026-04-10T16:00:00Z',
          'location': 'Main Hall',
        },
        {
          'id': 'evt-003',
          'title': 'Science Fair',
          'type': 'event',
          'startDate': '2026-04-15T08:00:00Z',
          'endDate': '2026-04-15T15:00:00Z',
          'location': 'Auditorium',
        },
        {
          'id': 'evt-004',
          'title': 'Staff Meeting',
          'type': 'meeting',
          'startDate': '2026-04-02T15:00:00Z',
          'endDate': '2026-04-02T16:00:00Z',
          'location': 'Conference Room',
        },
        {
          'id': 'evt-005',
          'title': 'Grade 9A Physics Lab',
          'type': 'class',
          'startDate': '2026-04-03T10:00:00Z',
          'endDate': '2026-04-03T11:30:00Z',
          'location': 'Lab 102',
        },
      ];

  // ─── Announcements ────────────────────────────────────
  static List<dynamic> get announcements => [
        {
          'id': 'ann-001',
          'title': 'Mid-Term Exam Schedule Released',
          'message': 'The mid-term examination schedule for all grades has been published. Please check the calendar for exact dates and rooms.',
          'targetAudience': ['student', 'teacher', 'parent'],
          'status': 'published',
          'createdAt': '2026-03-28T10:00:00Z',
          'author': {'firstName': 'Admin', 'lastName': 'Office'},
        },
        {
          'id': 'ann-002',
          'title': 'School Closure - National Holiday',
          'message': 'The school will be closed on April 8th for the national holiday. Classes resume on April 9th.',
          'targetAudience': ['student', 'teacher', 'parent'],
          'status': 'published',
          'createdAt': '2026-03-25T08:30:00Z',
          'author': {'firstName': 'Principal', 'lastName': 'Tesfaye'},
        },
        {
          'id': 'ann-003',
          'title': 'New Library Hours',
          'message': 'Starting April 1st, the library will remain open until 6:00 PM on weekdays. Weekend hours unchanged.',
          'targetAudience': ['student', 'teacher'],
          'status': 'published',
          'createdAt': '2026-03-22T14:00:00Z',
          'author': {'firstName': 'Library', 'lastName': 'Staff'},
        },
        {
          'id': 'ann-004',
          'title': 'Sports Day Registration Open',
          'message': 'Register for the upcoming Sports Day events. Deadline: April 12th. Contact your PE teacher.',
          'targetAudience': ['student'],
          'status': 'draft',
          'createdAt': '2026-03-20T09:00:00Z',
          'author': {'firstName': 'Sara', 'lastName': 'Ahmed'},
        },
      ];

  // ─── Exams ────────────────────────────────────────────
  static List<dynamic> get exams => [
        {
          'id': 'exam-001',
          'title': 'Mathematics Midterm',
          'status': 'published',
          'subject': {'name': 'Mathematics'},
          'maxPoints': 100,
          'durationMinutes': 120,
          'scheduledAt': '2026-04-05T09:00:00Z',
          'createdAt': '2026-03-15T10:00:00Z',
          'questionsCount': 25,
        },
        {
          'id': 'exam-002',
          'title': 'Physics Quiz - Chapter 5',
          'status': 'draft',
          'subject': {'name': 'Physics'},
          'maxPoints': 50,
          'durationMinutes': 45,
          'scheduledAt': '2026-04-08T10:00:00Z',
          'createdAt': '2026-03-20T14:00:00Z',
          'questionsCount': 15,
        },
        {
          'id': 'exam-003',
          'title': 'Chemistry Final',
          'status': 'published',
          'subject': {'name': 'Chemistry'},
          'maxPoints': 100,
          'durationMinutes': 150,
          'scheduledAt': '2026-03-20T09:00:00Z',
          'createdAt': '2026-03-01T10:00:00Z',
          'questionsCount': 40,
          'completedAt': '2026-03-20T12:30:00Z',
        },
      ];

  static List<dynamic> get examAttempts => [
        {
          'id': 'att-001',
          'student': {'id': 'stu-001', 'firstName': 'Ali', 'lastName': 'Hassan'},
          'submittedAt': '2026-03-20T11:45:00Z',
          'score': 87,
          'maxScore': 100,
          'releasedAt': '2026-03-22T10:00:00Z',
        },
        {
          'id': 'att-002',
          'student': {'id': 'stu-002', 'firstName': 'Fatima', 'lastName': 'Abdi'},
          'submittedAt': '2026-03-20T11:50:00Z',
          'score': 92,
          'maxScore': 100,
          'releasedAt': '2026-03-22T10:00:00Z',
        },
        {
          'id': 'att-003',
          'student': {'id': 'stu-003', 'firstName': 'Yusuf', 'lastName': 'Omar'},
          'submittedAt': '2026-03-20T12:00:00Z',
          'score': null,
          'maxScore': 100,
          'releasedAt': null,
        },
        {
          'id': 'att-004',
          'student': {'id': 'stu-004', 'firstName': 'Amina', 'lastName': 'Bekele'},
          'submittedAt': '2026-03-20T11:30:00Z',
          'score': 78,
          'maxScore': 100,
          'releasedAt': null,
        },
      ];

  // ─── Questions Bank ───────────────────────────────────
  static List<dynamic> get questions => [
        {
          'id': 'q-001',
          'text': 'Solve: 2x + 5 = 15',
          'type': 'short_answer',
          'subject': {'name': 'Mathematics'},
          'points': 5,
          'hasLatex': false,
          'hasImage': false,
        },
        {
          'id': 'q-002',
          'text': 'What is the derivative of f(x) = x³ + 2x?',
          'type': 'short_answer',
          'subject': {'name': 'Mathematics'},
          'points': 10,
          'hasLatex': true,
          'hasImage': false,
        },
        {
          'id': 'q-003',
          'text': 'Which of the following is a noble gas?',
          'type': 'multiple_choice',
          'subject': {'name': 'Chemistry'},
          'points': 5,
          'options': ['Oxygen', 'Nitrogen', 'Argon', 'Hydrogen'],
          'correctAnswer': 'Argon',
          'hasLatex': false,
          'hasImage': false,
        },
        {
          'id': 'q-004',
          'text': "Calculate the force needed to accelerate a 10kg object at 5m/s².",
          'type': 'short_answer',
          'subject': {'name': 'Physics'},
          'points': 8,
          'hasLatex': false,
          'hasImage': false,
        },
      ];

  // ─── Notifications ────────────────────────────────────
  static List<dynamic> get notifications => [
        {
          'id': 'notif-001',
          'title': 'New Assignment Submitted',
          'body': 'Ali Hassan submitted the Mathematics homework.',
          'type': 'assignment',
          'readAt': null,
          'createdAt': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
        },
        {
          'id': 'notif-002',
          'title': 'Exam Grading Reminder',
          'body': 'You have 3 ungraded submissions for Chemistry Final.',
          'type': 'exam',
          'readAt': null,
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'notif-003',
          'title': 'Parent Meeting Request',
          'body': 'Mohammed Hassan requested a meeting about Ali\'s progress.',
          'type': 'meeting',
          'readAt': null,
          'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'id': 'notif-004',
          'title': 'Attendance Report Ready',
          'body': 'Weekly attendance report for Grade 9A is available.',
          'type': 'report',
          'readAt': DateTime.now().subtract(const Duration(hours: 20)).toIso8601String(),
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': 'notif-005',
          'title': 'School Holiday Reminder',
          'body': 'School will be closed on April 8th for the national holiday.',
          'type': 'announcement',
          'readAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        },
      ];

  // ─── Conversations / Chat ─────────────────────────────
  static List<dynamic> get conversations => [
        {
          'id': 'conv-001',
          'participantName': 'Ms. Sara Ahmed',
          'name': 'Grade 9A - Mathematics',
          'participantRole': 'Mathematics Teacher',
          'subject': 'Mathematics',
          'avatar': '',
          'lastMessage': "Don't forget the homework!",
          'lastMessageTime': '10m ago',
          'read': false,
          'isGroup': true,
          'createdAt': '2026-03-01T08:00:00Z',
          'participants': [
            {'userId': 'teacher-001', 'firstName': 'Sara', 'lastName': 'Ahmed'},
          ],
          'unreadCount': 2,
        },
        {
          'id': 'conv-002',
          'participantName': 'Mohammed Hassan',
          'name': 'Mohammed Hassan',
          'participantRole': 'Parent',
          'subject': 'Parent Inbox',
          'avatar': '',
          'lastMessage': 'Thank you for the update on Ali\'s progress.',
          'lastMessageTime': '3h ago',
          'read': true,
          'isGroup': false,
          'createdAt': '2026-03-10T10:00:00Z',
          'participants': [
            {'userId': 'parent-001', 'firstName': 'Mohammed', 'lastName': 'Hassan'},
          ],
          'unreadCount': 0,
        },
        {
          'id': 'conv-003',
          'participantName': 'Science Department',
          'name': 'Science Department',
          'participantRole': 'Group Chat',
          'subject': 'Science',
          'avatar': '',
          'lastMessage': 'Meeting moved to Room 304.',
          'lastMessageTime': '1d ago',
          'read': false,
          'isGroup': true,
          'createdAt': '2026-02-15T08:00:00Z',
          'participants': [],
          'unreadCount': 1,
        },
        {
          'id': 'conv-004',
          'participantName': 'Ali Hassan',
          'name': 'Ali Hassan',
          'participantRole': 'Student – Grade 9A',
          'subject': 'Student Chat',
          'avatar': '',
          'lastMessage': 'Ms. Ahmed, I have a question about the assignment.',
          'lastMessageTime': '2h ago',
          'read': true,
          'isGroup': false,
          'createdAt': '2026-03-28T14:00:00Z',
          'participants': [
            {'userId': 'stu-001', 'firstName': 'Ali', 'lastName': 'Hassan'},
          ],
          'unreadCount': 0,
        },
      ];

  static List<dynamic> messages(String conversationId) => [
        {
          'id': 'msg-001',
          'conversationId': conversationId,
          'senderId': 'teacher-001',
          'text': 'Good morning everyone! Remember, the midterm is next week.',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'msg-002',
          'conversationId': conversationId,
          'senderId': 'stu-001',
          'text': 'Will it cover chapters 1-5?',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1, minutes: 50)).toIso8601String(),
        },
        {
          'id': 'msg-003',
          'conversationId': conversationId,
          'senderId': 'teacher-001',
          'text': 'Yes, chapters 1 through 5. Focus on the exercises at the end of each chapter.',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1, minutes: 45)).toIso8601String(),
        },
        {
          'id': 'msg-004',
          'conversationId': conversationId,
          'senderId': 'stu-002',
          'text': 'Thank you, Ms. Ahmed!',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),
        },
      ];

  // ─── Settings ─────────────────────────────────────────
  static Map<String, dynamic> get userSettings => {
        'darkMode': false,
        'pushNotifications': true,
        'emailNotifications': true,
        'predictiveInsights': true,
        'language': 'en',
      };

  // ─── Feedback ─────────────────────────────────────────
  static Map<String, dynamic> get feedbackResponse => {
        'id': 'fb-001',
        'status': 'submitted',
        'createdAt': DateTime.now().toIso8601String(),
      };

  static List<dynamic> get myFeedbackList => [
        {
          'id': 'fb-001',
          'authorId': 'user-001',
          'senderRole': 'parent',
          'category': 'general',
          'message': 'Great school environment!',
          'status': 'open',
          'isAnonymous': false,
          'createdAt': '2026-04-20T10:00:00.000Z',
        },
        {
          'id': 'fb-002',
          'authorId': 'user-001',
          'senderRole': 'parent',
          'category': 'teacher',
          'message': 'Excellent teaching methods',
          'status': 'resolved',
          'teacherId': 'teacher-001',
          'subjectId': 'subject-001',
          'isAnonymous': false,
          'createdAt': '2026-04-15T09:00:00.000Z',
        },
      ];

  static List<dynamic> get teacherFeedbackList => [
        {
          'id': 'fb-t-001',
          'authorId': null,
          'senderRole': 'student',
          'category': 'teacher',
          'message': 'Please slow down during explanations, it is hard to follow.',
          'status': 'open',
          'teacherId': 'teacher-001',
          'subjectId': 'subject-001',
          'isAnonymous': true,
          'sender': null,
          'createdAt': '2026-04-22T09:00:00.000Z',
        },
        {
          'id': 'fb-t-002',
          'authorId': 'user-002',
          'senderRole': 'parent',
          'category': 'teacher',
          'message': 'My child really enjoys your classes. Thank you for the extra support!',
          'status': 'open',
          'teacherId': 'teacher-001',
          'subjectId': null,
          'isAnonymous': false,
          'sender': {
            'id': 'user-002',
            'firstName': 'Amina',
            'lastName': 'Hassan',
            'email': 'amina@example.com',
            'role': 'parent',
          },
          'createdAt': '2026-04-20T14:30:00.000Z',
        },
        {
          'id': 'fb-t-003',
          'authorId': null,
          'senderRole': 'student',
          'category': 'teacher',
          'message': 'More practice problems would be very helpful before exams.',
          'status': 'resolved',
          'teacherId': 'teacher-001',
          'subjectId': 'subject-001',
          'isAnonymous': true,
          'sender': null,
          'createdAt': '2026-04-18T11:00:00.000Z',
        },
      ];

  // ─── Reports ──────────────────────────────────────────
  static Map<String, dynamic> studentPerformance(String studentId) => {
        'studentId': studentId,
        'termAverage': 89,
        'gpa': '3.8',
        'classRank': '5th out of 32 students',
        'grade': 'Grade 9 – Section A',
        'semester': 'Semester 2, 2025/2026',
        'subjects': [
          {
            'name': 'Mathematics',
            'teacher': 'Ms. Sara Ahmed',
            'grade': '92%',
            'gradeLabel': 'A',
            'details': [
              {'name': 'Midterm Exam', 'grade': '88%'},
              {'name': 'Final Exam', 'grade': '94%'},
              {'name': 'Homework', 'grade': '96%'},
              {'name': 'Participation', 'grade': '90%'},
            ],
            'trend': [82.0, 85.0, 88.0, 92.0],
          },
          {
            'name': 'Physics',
            'teacher': 'Mr. Dawit Lemma',
            'grade': '88%',
            'gradeLabel': 'B+',
            'details': [
              {'name': 'Midterm Exam', 'grade': '85%'},
              {'name': 'Final Exam', 'grade': '90%'},
              {'name': 'Lab Work', 'grade': '88%'},
            ],
            'trend': [78.0, 82.0, 85.0, 88.0],
          },
          {
            'name': 'English',
            'teacher': 'Mr. John Peters',
            'grade': '91%',
            'gradeLabel': 'A',
            'details': [
              {'name': 'Essay', 'grade': '93%'},
              {'name': 'Reading', 'grade': '89%'},
              {'name': 'Grammar', 'grade': '91%'},
            ],
            'trend': [85.0, 88.0, 90.0, 91.0],
          },
          {
            'name': 'History',
            'teacher': 'Ms. Rahel Mengistu',
            'grade': '87%',
            'gradeLabel': 'B+',
          },
          {
            'name': 'Chemistry',
            'teacher': 'Ms. Helen Tadesse',
            'grade': '85%',
            'gradeLabel': 'B+',
          },
        ],
      };

  static Map<String, dynamic> studentCompare(String studentId) => {
        'studentId': studentId,
        'current': {'termAverage': 89.3, 'attendancePercent': 95.0, 'gpa': 3.8},
        'previous': {'termAverage': 87.5, 'attendancePercent': 92.0, 'gpa': 3.7},
        'subjects': [
          {'name': 'Mathematics', 'current': 92, 'previous': 88, 'change': 4},
          {'name': 'Physics', 'current': 88, 'previous': 85, 'change': 3},
          {'name': 'Chemistry', 'current': 85, 'previous': 86, 'change': -1},
          {'name': 'English', 'current': 91, 'previous': 89, 'change': 2},
          {'name': 'History', 'current': 87, 'previous': 90, 'change': -3},
        ],
        'notes': 'Overall improvement of 1.8 points. Strong progress in Mathematics and Physics.',
      };

  static Map<String, dynamic> get parentWeeklySummary => {
        'weekLabel': 'Mar 24 – Mar 28',
        'overallGrade': '89.3%',
        'summary':
            'Ali had an excellent week overall. Strong performance in Mathematics and English with perfect attendance.',
        'highlights': [
          'Scored 95% on Math quiz',
          'Perfect attendance this week',
          'Participated in Science Fair prep',
          'Submitted all assignments on time',
        ],
        'subjects': [
          {'name': 'Mathematics', 'grade': '95%'},
          {'name': 'Physics', 'grade': '88%'},
          {'name': 'English', 'grade': '91%'},
          {'name': 'Chemistry', 'grade': '85%'},
          {'name': 'History', 'grade': '87%'},
        ],
        'attendanceRate': '100',
      };

  // ─── Student Profile ──────────────────────────────────
  static Map<String, dynamic> studentProfile(String userId) => {
        'id': userId,
        'firstName': 'Ali',
        'lastName': 'Hassan',
        'fullName': 'Ali Hassan',
        'email': 'ali.hassan@school.edu',
        'grade': 'Grade 9',
        'section': 'A',
        'gradeSection': 'Grade 9 • Section A',
        'phone': null,
        'studentId': 'STU-2026-04821',
        'classes': [
          {'subject': 'Mathematics', 'teacher': 'Ms. Sara Ahmed', 'schedule': 'Mon/Wed 9:00', 'room': '201'},
          {'subject': 'Physics', 'teacher': 'Mr. Dawit Lemma', 'schedule': 'Tue/Thu 10:00', 'room': '305'},
          {'subject': 'Chemistry', 'teacher': 'Ms. Helen Tadesse', 'schedule': 'Mon/Wed 11:00', 'room': 'Lab 102'},
          {'subject': 'English', 'teacher': 'Mr. John Peters', 'schedule': 'Tue/Thu 9:00', 'room': '108'},
          {'subject': 'History', 'teacher': 'Ms. Rahel Mengistu', 'schedule': 'Fri 10:00', 'room': '204'},
        ],
        'teachers': [
          {'name': 'Ms. Sara Ahmed'},
          {'name': 'Mr. Dawit Lemma'},
          {'name': 'Ms. Helen Tadesse'},
          {'name': 'Mr. John Peters'},
          {'name': 'Ms. Rahel Mengistu'},
        ],
      };

  // ─── Attempt Result (parent view) ─────────────────────
  static Map<String, dynamic> attemptResult(String attemptId) => {
        'id': attemptId,
        'examTitle': 'Chemistry Final',
        'score': 87,
        'maxScore': 100,
        'percentage': 87.0,
        'grade': 'B+',
        'submittedAt': '2026-03-20T11:45:00Z',
        'releasedAt': '2026-03-22T10:00:00Z',
      };

  // ─── Attempt for Grader (teacher view) ────────────────
  static Map<String, dynamic> attemptForGrader(String attemptId) => {
        'id': attemptId,
        'student': {'id': 'stu-003', 'firstName': 'Yusuf', 'lastName': 'Omar'},
        'exam': {'title': 'Chemistry Final', 'maxPoints': 100},
        'answers': [
          {'questionText': 'What is the atomic number of Carbon?', 'answer': '6', 'points': 5},
          {'questionText': 'Explain covalent bonding.', 'answer': 'Covalent bonding is the sharing of electrons between atoms...', 'points': 10},
          {'questionText': 'Balance: H2 + O2 → H2O', 'answer': '2H2 + O2 → 2H2O', 'points': 8},
        ],
        'submittedAt': '2026-03-20T12:00:00Z',
      };

  // ═══════════════════════════════════════════════════════
  // ─── PARENT-SPECIFIC DATA ──────────────────────────────
  // ═══════════════════════════════════════════════════════

  // ─── My Children (Parent-Student Links) ────────────────
  static List<dynamic> get myChildren => [
        {
          'id': 'link-001',
          'parentId': 'parent-001',
          'studentId': 'stu-001',
          'relationship': 'Father',
          'isPrimary': true,
          'createdAt': '2025-09-01T08:00:00Z',
          'student': {
            'id': 'stu-001',
            'firstName': 'Ali',
            'lastName': 'Hassan',
            'email': 'ali.hassan@school.edu',
            'grade': 'Grade 9',
            'section': 'A',
          },
        },
        {
          'id': 'link-002',
          'parentId': 'parent-001',
          'studentId': 'stu-010',
          'relationship': 'Father',
          'isPrimary': false,
          'createdAt': '2025-09-01T08:00:00Z',
          'student': {
            'id': 'stu-010',
            'firstName': 'Leila',
            'lastName': 'Hassan',
            'email': 'leila.hassan@school.edu',
            'grade': 'Grade 7',
            'section': 'B',
          },
        },
      ];

  // ─── Child Enrollments ─────────────────────────────────
  static List<dynamic> childEnrollments(String studentId) => [
        {
          'enrollmentId': 'enr-001',
          'academicYearId': 'ay-001',
          'classOfferingId': 'co-001',
          'className': 'Grade 9-A Mathematics',
          'grade': 'Grade 9',
          'section': 'A',
          'subject': {
            'id': 'sub-001',
            'name': 'Mathematics',
            'code': 'MATH-9',
          },
          'teacher': {
            'id': 'teacher-001',
            'firstName': 'Sara',
            'lastName': 'Ahmed',
            'email': 'sara.ahmed@school.edu',
          },
          'schedule': 'Mon/Wed 9:00 AM',
          'room': 'Room 201',
        },
        {
          'enrollmentId': 'enr-002',
          'academicYearId': 'ay-001',
          'classOfferingId': 'co-002',
          'className': 'Grade 9-A Physics',
          'grade': 'Grade 9',
          'section': 'A',
          'subject': {
            'id': 'sub-002',
            'name': 'Physics',
            'code': 'PHY-9',
          },
          'teacher': {
            'id': 'teacher-002',
            'firstName': 'Dawit',
            'lastName': 'Lemma',
            'email': 'dawit.lemma@school.edu',
          },
          'schedule': 'Tue/Thu 10:00 AM',
          'room': 'Lab 305',
        },
        {
          'enrollmentId': 'enr-003',
          'academicYearId': 'ay-001',
          'classOfferingId': 'co-003',
          'className': 'Grade 9-A Chemistry',
          'grade': 'Grade 9',
          'section': 'A',
          'subject': {
            'id': 'sub-003',
            'name': 'Chemistry',
            'code': 'CHEM-9',
          },
          'teacher': {
            'id': 'teacher-003',
            'firstName': 'Helen',
            'lastName': 'Tadesse',
            'email': 'helen.tadesse@school.edu',
          },
          'schedule': 'Mon/Wed 11:00 AM',
          'room': 'Lab 102',
        },
        {
          'enrollmentId': 'enr-004',
          'academicYearId': 'ay-001',
          'classOfferingId': 'co-004',
          'className': 'Grade 9-A English',
          'grade': 'Grade 9',
          'section': 'A',
          'subject': {
            'id': 'sub-004',
            'name': 'English',
            'code': 'ENG-9',
          },
          'teacher': {
            'id': 'teacher-004',
            'firstName': 'John',
            'lastName': 'Peters',
            'email': 'john.peters@school.edu',
          },
          'schedule': 'Tue/Thu 9:00 AM',
          'room': 'Room 108',
        },
        {
          'enrollmentId': 'enr-005',
          'academicYearId': 'ay-001',
          'classOfferingId': 'co-005',
          'className': 'Grade 9-A History',
          'grade': 'Grade 9',
          'section': 'A',
          'subject': {
            'id': 'sub-005',
            'name': 'History',
            'code': 'HIST-9',
          },
          'teacher': {
            'id': 'teacher-005',
            'firstName': 'Rahel',
            'lastName': 'Mengistu',
            'email': 'rahel.mengistu@school.edu',
          },
          'schedule': 'Fri 10:00 AM',
          'room': 'Room 204',
        },
        {
          'enrollmentId': 'enr-006',
          'academicYearId': 'ay-001',
          'classOfferingId': 'co-006',
          'className': 'Grade 9-A Biology',
          'grade': 'Grade 9',
          'section': 'A',
          'subject': {
            'id': 'sub-006',
            'name': 'Biology',
            'code': 'BIO-9',
          },
          'teacher': {
            'id': 'teacher-006',
            'firstName': 'Meron',
            'lastName': 'Bekele',
            'email': 'meron.bekele@school.edu',
          },
          'schedule': 'Wed/Fri 2:00 PM',
          'room': 'Lab 201',
        },
      ];

  // ─── Child Goals ───────────────────────────────────────
  static List<dynamic> childGoals(String studentId) => [
        {
          'id': 'goal-001',
          'studentId': studentId,
          'title': 'Improve Algebra Skills',
          'description': 'Practice algebra problems for 30 minutes daily and complete all homework assignments on time.',
          'targetDate': '2026-06-01',
          'status': 'active',
          'progressPercent': 65,
          'createdAt': '2026-02-15T10:00:00Z',
          'updatedAt': '2026-04-08T14:30:00Z',
        },
        {
          'id': 'goal-002',
          'studentId': studentId,
          'title': 'Perfect Attendance',
          'description': 'Maintain 100% attendance for the entire term.',
          'targetDate': '2026-06-30',
          'status': 'active',
          'progressPercent': 95,
          'createdAt': '2026-01-10T08:00:00Z',
          'updatedAt': '2026-04-09T09:00:00Z',
        },
        {
          'id': 'goal-003',
          'studentId': studentId,
          'title': 'Science Fair Project',
          'description': 'Complete and present a science fair project on renewable energy.',
          'targetDate': '2026-04-15',
          'status': 'active',
          'progressPercent': 80,
          'createdAt': '2026-03-01T10:00:00Z',
          'updatedAt': '2026-04-07T16:00:00Z',
        },
        {
          'id': 'goal-004',
          'studentId': studentId,
          'title': 'Read 10 Books',
          'description': 'Read at least 10 books this semester to improve reading comprehension.',
          'targetDate': '2026-06-30',
          'status': 'active',
          'progressPercent': 40,
          'createdAt': '2026-01-15T08:00:00Z',
          'updatedAt': '2026-04-05T12:00:00Z',
        },
      ];

  // ─── Parent Notifications ──────────────────────────────
  static List<dynamic> get parentNotifications => [
        {
          'id': 'notif-p001',
          'userId': 'parent-001',
          'type': 'attendance',
          'title': 'Attendance Alert',
          'body': 'Ali was marked absent in Mathematics class on April 8, 2026.',
          'payloadJson': '{"studentId":"stu-001","date":"2026-04-08","subject":"Mathematics"}',
          'readAt': null,
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'notif-p002',
          'userId': 'parent-001',
          'type': 'exam',
          'title': 'Exam Result Released',
          'body': 'Ali\'s Chemistry Final exam result has been released. Score: 87/100',
          'payloadJson': '{"studentId":"stu-001","examId":"exam-003","score":87}',
          'readAt': null,
          'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        },
        {
          'id': 'notif-p003',
          'userId': 'parent-001',
          'type': 'announcement',
          'title': 'Parent-Teacher Meeting',
          'body': 'Parent-Teacher conference scheduled for April 10, 2026 at 2:00 PM.',
          'payloadJson': '{"eventId":"evt-002","date":"2026-04-10"}',
          'readAt': null,
          'createdAt': DateTime.now().subtract(const Duration(hours: 24)).toIso8601String(),
        },
        {
          'id': 'notif-p004',
          'userId': 'parent-001',
          'type': 'grade',
          'title': 'New Grade Posted',
          'body': 'Ali received 92% on the Mathematics Midterm exam.',
          'payloadJson': '{"studentId":"stu-001","subject":"Mathematics","grade":92}',
          'readAt': DateTime.now().subtract(const Duration(hours: 30)).toIso8601String(),
          'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'id': 'notif-p005',
          'userId': 'parent-001',
          'type': 'attendance',
          'title': 'Perfect Attendance Week',
          'body': 'Congratulations! Leila had perfect attendance this week.',
          'payloadJson': '{"studentId":"stu-010","week":"2026-W14"}',
          'readAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        },
      ];

  // ─── Parent Announcements ──────────────────────────────
  static List<dynamic> get parentAnnouncements => [
        {
          'id': 'ann-p001',
          'title': 'Parent-Teacher Conference Schedule',
          'message': 'The parent-teacher conferences will be held on April 10-12. Please check your email for your scheduled time slot.',
          'targetAudience': ['parent'],
          'status': 'published',
          'createdAt': '2026-04-01T10:00:00Z',
          'author': {'firstName': 'Principal', 'lastName': 'Tesfaye'},
        },
        {
          'id': 'ann-p002',
          'title': 'School Fees Payment Reminder',
          'message': 'Reminder: Second semester fees are due by April 15, 2026. Please visit the finance office or pay online.',
          'targetAudience': ['parent'],
          'status': 'published',
          'createdAt': '2026-03-28T09:00:00Z',
          'author': {'firstName': 'Finance', 'lastName': 'Office'},
        },
        {
          'id': 'ann-p003',
          'title': 'Science Fair - Parent Invitation',
          'message': 'You are invited to attend the annual Science Fair on April 15, 2026 from 8:00 AM to 3:00 PM in the school auditorium.',
          'targetAudience': ['parent', 'student'],
          'status': 'published',
          'createdAt': '2026-03-25T14:00:00Z',
          'author': {'firstName': 'Science', 'lastName': 'Department'},
        },
        {
          'id': 'ann-p004',
          'title': 'Updated School Calendar',
          'message': 'The school calendar has been updated with new exam dates. Please check the calendar section for details.',
          'targetAudience': ['parent', 'student', 'teacher'],
          'status': 'published',
          'createdAt': '2026-03-20T11:00:00Z',
          'author': {'firstName': 'Admin', 'lastName': 'Office'},
        },
      ];

  // ─── Child Performance Report (Enhanced) ───────────────
  static Map<String, dynamic> childPerformanceReport(String studentId) => {
        'studentId': studentId,
        'student': {
          'firstName': 'Ali',
          'lastName': 'Hassan',
          'grade': 'Grade 9',
          'section': 'A',
        },
        'generatedAt': DateTime.now().toIso8601String(),
        'attendanceAllTime': {
          'totalMarks': 120,
          'byStatus': {'present': 100, 'late': 8, 'absent': 12},
          'presentOrLateRate': 0.9,
        },
        'attendanceLast90Days': {
          'totalMarks': 30,
          'byStatus': {'present': 25, 'late': 2, 'absent': 3},
          'presentOrLateRate': 0.9,
        },
        'examsReleased': {
          'releasedAttempts': 5,
          'averageScore': 87.4,
          'recent': [
            {
              'examTitle': 'Mathematics Midterm',
              'score': 92,
              'maxScore': 100,
              'releasedAt': '2026-04-05T10:00:00Z',
            },
            {
              'examTitle': 'Chemistry Final',
              'score': 87,
              'maxScore': 100,
              'releasedAt': '2026-03-22T10:00:00Z',
            },
            {
              'examTitle': 'Physics Quiz',
              'score': 85,
              'maxScore': 100,
              'releasedAt': '2026-03-15T14:00:00Z',
            },
          ],
        },
        'overallGPA': 3.8,
        'termAverage': 89.3,
        'classRank': '5th out of 32 students',
      };

  // ─── Period Comparison Report ──────────────────────────
  static Map<String, dynamic> periodComparisonReport(String studentId) => {
        'studentId': studentId,
        'period1': {
          'start': '2026-01-01',
          'end': '2026-02-15',
          'attendance': {
            'totalMarks': 45,
            'byStatus': {'present': 40, 'late': 3, 'absent': 2},
            'presentOrLateRate': 0.956,
          },
          'exams': {
            'count': 3,
            'averageScore': 85.3,
          },
          'termAverage': 87.5,
        },
        'period2': {
          'start': '2026-02-16',
          'end': '2026-03-31',
          'attendance': {
            'totalMarks': 42,
            'byStatus': {'present': 38, 'late': 2, 'absent': 2},
            'presentOrLateRate': 0.952,
          },
          'exams': {
            'count': 4,
            'averageScore': 88.5,
          },
          'termAverage': 89.3,
        },
        'comparison': {
          'attendanceChange': -0.004,
          'examScoreChange': 3.2,
          'termAverageChange': 1.8,
          'trend': 'improving',
        },
      };

  // ─── Weekly Parent Summary (Enhanced) ──────────────────
  static Map<String, dynamic> weeklyParentSummary({String? childStudentId}) => {
        'weekFrom': '2026-04-02',
        'weekThrough': '2026-04-09',
        'generatedAt': DateTime.now().toIso8601String(),
        'children': [
          {
            'studentId': 'stu-001',
            'name': 'Ali Hassan',
            'attendanceThisWeek': {
              'totalMarks': 5,
              'byStatus': {'present': 4, 'late': 1, 'absent': 0},
              'presentOrLateRate': 1.0,
            },
            'examsReleasedThisWeek': 1,
            'exams': [
              {
                'title': 'Mathematics Midterm',
                'score': 92,
                'maxScore': 100,
                'releasedAt': '2026-04-05T10:00:00Z',
              },
            ],
            'highlights': [
              'Scored 92% on Mathematics Midterm',
              'Perfect attendance this week',
              'Completed all homework assignments',
            ],
            'concerns': [],
          },
          if (childStudentId == null)
            {
              'studentId': 'stu-010',
              'name': 'Leila Hassan',
              'attendanceThisWeek': {
                'totalMarks': 5,
                'byStatus': {'present': 5, 'late': 0, 'absent': 0},
                'presentOrLateRate': 1.0,
              },
              'examsReleasedThisWeek': 0,
              'exams': [],
              'highlights': [
                'Perfect attendance this week',
                'Participated in Science Fair preparation',
              ],
              'concerns': [],
            },
        ],
      };

  // ─── Parent Calendar Events ────────────────────────────
  static List<dynamic> get parentCalendarEvents => [
        {
          'id': 'evt-p001',
          'academicYearId': 'ay-001',
          'title': 'Parent-Teacher Conference',
          'date': '2026-04-10',
          'time': '14:00',
          'type': 'meeting',
          'description': 'Individual parent-teacher meetings to discuss student progress.',
          'classOfferingId': null,
          'createdById': 'admin-001',
          'createdAt': '2026-03-15T10:00:00Z',
          'updatedAt': '2026-03-15T10:00:00Z',
        },
        {
          'id': 'evt-p002',
          'academicYearId': 'ay-001',
          'title': 'Science Fair',
          'date': '2026-04-15',
          'time': '08:00',
          'type': 'event',
          'description': 'Annual school science fair. Parents are welcome to attend.',
          'classOfferingId': null,
          'createdById': 'admin-001',
          'createdAt': '2026-03-20T09:00:00Z',
          'updatedAt': '2026-03-20T09:00:00Z',
        },
        {
          'id': 'evt-p003',
          'academicYearId': 'ay-001',
          'title': 'School Holiday',
          'date': '2026-04-08',
          'time': '00:00',
          'type': 'holiday',
          'description': 'National holiday - school closed.',
          'classOfferingId': null,
          'createdById': 'admin-001',
          'createdAt': '2026-03-01T10:00:00Z',
          'updatedAt': '2026-03-01T10:00:00Z',
        },
        {
          'id': 'evt-p004',
          'academicYearId': 'ay-001',
          'title': 'Grade 9 Math Exam',
          'date': '2026-04-05',
          'time': '09:00',
          'type': 'exam',
          'description': 'Mathematics midterm examination for Grade 9.',
          'classOfferingId': 'co-001',
          'createdById': 'teacher-001',
          'createdAt': '2026-03-15T10:00:00Z',
          'updatedAt': '2026-03-15T10:00:00Z',
        },
        {
          'id': 'evt-p005',
          'academicYearId': 'ay-001',
          'title': 'Sports Day',
          'date': '2026-04-20',
          'time': '08:00',
          'type': 'event',
          'description': 'Annual sports day event. Parents are invited to attend.',
          'classOfferingId': null,
          'createdById': 'admin-001',
          'createdAt': '2026-03-25T10:00:00Z',
          'updatedAt': '2026-03-25T10:00:00Z',
        },
      ];

  // ─── Exam Results for Parent ───────────────────────────
  static List<dynamic> childExamResults(String studentId) => [
        {
          'attemptId': 'att-001',
          'examId': 'exam-001',
          'examTitle': 'Mathematics Midterm',
          'subject': 'Mathematics',
          'maxPoints': 100,
          'score': 92,
          'percentage': 92.0,
          'grade': 'A',
          'autoScore': 92,
          'needsManualGrading': false,
          'submittedAt': '2026-04-05T11:00:00Z',
          'releasedAt': '2026-04-05T15:00:00Z',
          'teacher': 'Ms. Sara Ahmed',
        },
        {
          'attemptId': 'att-002',
          'examId': 'exam-003',
          'examTitle': 'Chemistry Final',
          'subject': 'Chemistry',
          'maxPoints': 100,
          'score': 87,
          'percentage': 87.0,
          'grade': 'B+',
          'autoScore': 85,
          'needsManualGrading': false,
          'submittedAt': '2026-03-20T11:45:00Z',
          'releasedAt': '2026-03-22T10:00:00Z',
          'teacher': 'Ms. Helen Tadesse',
        },
        {
          'attemptId': 'att-003',
          'examId': 'exam-002',
          'examTitle': 'Physics Quiz - Chapter 5',
          'subject': 'Physics',
          'maxPoints': 50,
          'score': 43,
          'percentage': 86.0,
          'grade': 'B+',
          'autoScore': 43,
          'needsManualGrading': false,
          'submittedAt': '2026-03-15T10:30:00Z',
          'releasedAt': '2026-03-15T14:00:00Z',
          'teacher': 'Mr. Dawit Lemma',
        },
      ];
}
