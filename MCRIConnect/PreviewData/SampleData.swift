import Foundation

/// Realistic sample content for previews and the mock service layer. Swap
/// `AppStore` for a Supabase-backed implementation and this file is the only
/// thing that leaves the build.
enum SampleData {
    static let calendar = Calendar.current

    static func days(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
    }

    static func hours(_ offset: Int) -> Date {
        calendar.date(byAdding: .hour, value: offset, to: Date()) ?? Date()
    }

    // MARK: Companies

    static let orbitLabs = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
                                   name: "Orbit Labs", initials: "O", teamLabel: "Talent team",
                                   openRoles: 4, hiredLastCycle: 6)
    static let northstar = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
                                   name: "Northstar Labs", initials: "N", teamLabel: "Mobile guild · 2 open roles",
                                   openRoles: 2, hiredLastCycle: 3)
    static let mcriAnalytics = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003")!,
                                       name: "MCRI Analytics", initials: "M", teamLabel: "Data practice · 3 open roles",
                                       openRoles: 3, hiredLastCycle: 4)
    static let vantageHealth = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000004")!,
                                       name: "Vantage Health", initials: "V", teamLabel: "Product · 1 open role",
                                       openRoles: 1, hiredLastCycle: 2)
    static let kasiFintech = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000005")!,
                                     name: "Kasi Fintech", initials: "K", teamLabel: "Growth · 2 open roles",
                                     openRoles: 2, hiredLastCycle: 5)

    static let companies: [Company] = [orbitLabs, northstar, mcriAnalytics, vantageHealth, kasiFintech]

    // MARK: Internships

    static let productDesignIntern = Internship(
        id: UUID(uuidString: "B0000000-0000-0000-0000-000000000001")!,
        title: "Product Design Intern", companyID: orbitLabs.id, companyName: orbitLabs.name,
        companyInitials: orbitLabs.initials, location: "Remote · South Africa", workMode: .remote,
        durationWeeks: 12, compensation: "R14 000 / month", isPaid: true, easyApply: true,
        postedDate: days(-21), closingDate: days(14),
        description: "Join the Orbit Labs product guild for a 12-week internship covering discovery, "
            + "design and hand-off. You will own one surface end to end with a senior designer as your reviewer.",
        responsibilities: [
            "Run two user interviews a week and synthesise the findings",
            "Design, prototype and test one feature per sprint",
            "Present work in the Friday product review",
            "Maintain Figma components in the shared design system",
        ],
        requiredSkills: ["Figma", "User research", "Prototyping", "Communication"],
        preferredSkills: ["Design systems", "Accessibility"],
        careerInterests: ["Product Design", "UX Research"],
        applicants: 18, teamSize: 6, category: .design)

    static let mobileDevIntern = Internship(
        id: UUID(uuidString: "B0000000-0000-0000-0000-000000000002")!,
        title: "Mobile Developer Intern", companyID: northstar.id, companyName: northstar.name,
        companyInitials: northstar.initials, location: "Cape Town", workMode: .hybrid,
        durationWeeks: 10, compensation: "R12 500 / month", isPaid: true, easyApply: false,
        postedDate: days(-14), closingDate: days(9),
        description: "Ship customer-facing screens in SwiftUI alongside the Northstar mobile guild, "
            + "with real releases behind a feature flag from week three.",
        responsibilities: [
            "Build and unit-test SwiftUI screens",
            "Fix accessibility audit items with the QA pair",
            "Take part in code review on every pull request",
        ],
        requiredSkills: ["SwiftUI", "Git", "Accessibility", "Xcode"],
        preferredSkills: ["Combine", "Unit testing"],
        careerInterests: ["Front-end", "Mobile"],
        applicants: 24, teamSize: 5, category: .technology)

    static let dataAnalystIntern = Internship(
        id: UUID(uuidString: "B0000000-0000-0000-0000-000000000003")!,
        title: "Data Analyst Intern", companyID: mcriAnalytics.id, companyName: mcriAnalytics.name,
        companyInitials: mcriAnalytics.initials, location: "Durban", workMode: .onSite,
        durationWeeks: 16, compensation: "R15 000 / month", isPaid: true, easyApply: true,
        postedDate: days(-9), closingDate: days(21),
        description: "Support the placement analytics practice with reporting that programme managers "
            + "act on weekly. You will own one dashboard from intake to launch.",
        responsibilities: [
            "Write and review SQL against the placement warehouse",
            "Build one executive dashboard and keep it current",
            "Flag data quality issues to the analytics lead",
        ],
        requiredSkills: ["SQL", "Python", "Dashboards", "Statistics"],
        preferredSkills: ["Data storytelling"],
        careerInterests: ["Data", "Analytics"],
        applicants: 11, teamSize: 6, category: .data)

    static let healthUXIntern = Internship(
        id: UUID(uuidString: "B0000000-0000-0000-0000-000000000004")!,
        title: "UX Research Intern", companyID: vantageHealth.id, companyName: vantageHealth.name,
        companyInitials: vantageHealth.initials, location: "Remote · Cape Town", workMode: .remote,
        durationWeeks: 24, compensation: "R16 000 / month", isPaid: true, easyApply: false,
        postedDate: days(-4), closingDate: days(3),
        description: "Run longitudinal research into how clinic staff triage digital referrals, "
            + "with findings presented to the clinical board.",
        responsibilities: [
            "Recruit and moderate weekly sessions",
            "Maintain the research repository",
            "Write one insight brief per month",
        ],
        requiredSkills: ["User research", "Interviewing", "Synthesis"],
        preferredSkills: ["Figma", "Healthcare domain"],
        careerInterests: ["UX Research", "Health"],
        applicants: 7, teamSize: 3, category: .research)

    static let growthMarketingIntern = Internship(
        id: UUID(uuidString: "B0000000-0000-0000-0000-000000000005")!,
        title: "Growth Marketing Intern", companyID: kasiFintech.id, companyName: kasiFintech.name,
        companyInitials: kasiFintech.initials, location: "Johannesburg", workMode: .hybrid,
        durationWeeks: 12, compensation: "Unpaid · stipend on review", isPaid: false, easyApply: true,
        postedDate: days(-2), closingDate: days(28),
        description: "Own the experiment queue for a savings product used by 40 000 people, "
            + "from hypothesis to readout.",
        responsibilities: [
            "Draft and run weekly acquisition experiments",
            "Report funnel movement to the growth lead",
        ],
        requiredSkills: ["Analytics", "Copywriting", "Excel"],
        preferredSkills: ["SQL", "Dashboards"],
        careerInterests: ["Marketing", "Business"],
        applicants: 31, teamSize: 4, category: .business)

    static let backendIntern = Internship(
        id: UUID(uuidString: "B0000000-0000-0000-0000-000000000006")!,
        title: "Backend Engineering Intern", companyID: orbitLabs.id, companyName: orbitLabs.name,
        companyInitials: orbitLabs.initials, location: "Remote · South Africa", workMode: .remote,
        durationWeeks: 16, compensation: "R17 000 / month", isPaid: true, easyApply: true,
        postedDate: days(-30), closingDate: days(6),
        description: "Work on the matching service that powers this app: queues, scoring and the "
            + "API the mobile clients read from.",
        responsibilities: [
            "Ship endpoints behind a reviewed pull request",
            "Add contract tests to the matching service",
            "Instrument one slow path and make it faster",
        ],
        requiredSkills: ["Swift", "PostgreSQL", "REST APIs"],
        preferredSkills: ["Docker", "Unit testing"],
        careerInterests: ["Back-end", "Mobile"],
        applicants: 15, teamSize: 8, category: .technology)

    static let internships: [Internship] = [
        productDesignIntern, mobileDevIntern, dataAnalystIntern,
        healthUXIntern, growthMarketingIntern, backendIntern,
    ]

    // MARK: Students

    static let alex = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000001")!,
        fullName: "Alex Mensah", initials: "AM", programme: "BSc Product Design", year: "Year 2",
        city: "Cape Town", workMode: .remote, availability: .juneWindow,
        bio: "Design student who ships what they draw. Two years of studio work, one campus app in production.",
        skills: [
            StudentSkill(name: "Figma", category: .design, proficiency: .advanced,
                         evidence: "Design system with 48 components used across three student teams"),
            StudentSkill(name: "User research", category: .research, proficiency: .advanced,
                         evidence: "Ran 14 interviews for the campus events app"),
            StudentSkill(name: "Prototyping", category: .design, proficiency: .advanced,
                         evidence: "Interactive prototype tested with 20 students"),
            StudentSkill(name: "Communication", category: .communication, proficiency: .advanced,
                         evidence: "Presented studio crits to a panel of three practising designers"),
            StudentSkill(name: "SwiftUI", category: .technology, proficiency: .intermediate,
                         evidence: "Built the booking flow for the campus events app"),
            StudentSkill(name: "Git", category: .technology, proficiency: .intermediate),
        ],
        interests: ["Product Design", "UX Research"],
        projects: [
            Project(title: "Campus events app",
                    summary: "Designed and built an event booking app in SwiftUI and Firebase",
                    outcome: "Used by 25 students in its first month", year: 2026),
            Project(title: "Transit wayfinding study",
                    summary: "Redesigned the MyCiTi interchange signage after a 30-person field study",
                    outcome: "Adopted for the pilot at one station", year: 2025),
        ],
        cvFileName: "Alex_Mensah_CV.pdf", profileStrength: 78, advisor: "Nomsa Dube")

    static let jordan = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000002")!,
        fullName: "Jordan Lee", initials: "JL", programme: "BA Design Computing", year: "Year 3",
        city: "Cape Town", workMode: .hybrid, availability: .juneWindow,
        bio: "Design-computing hybrid: researches, prototypes and builds the thing.",
        skills: [
            StudentSkill(name: "Figma", category: .design, proficiency: .expert,
                         evidence: "Owns the faculty design-system library"),
            StudentSkill(name: "User research", category: .research, proficiency: .advanced,
                         evidence: "Ran a 3-part diary study on student budgeting"),
            StudentSkill(name: "Communication", category: .communication, proficiency: .expert,
                         evidence: "Guest critic at two design studios"),
            StudentSkill(name: "Prototyping", category: .design, proficiency: .expert),
            StudentSkill(name: "Accessibility", category: .design, proficiency: .advanced,
                         evidence: "Audited three campus apps against WCAG AA"),
        ],
        interests: ["Product Design", "UX Research"],
        projects: [
            Project(title: "Campus event booking app",
                    summary: "Designed and shipped a booking flow used across three societies",
                    outcome: "Used by 25 students in its first month", year: 2026),
        ],
        cvFileName: "Jordan_Lee_CV.pdf", profileStrength: 92, advisor: "Nomsa Dube")

    static let maya = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000003")!,
        fullName: "Maya Chen", initials: "MC", programme: "BSc Information Systems", year: "Year 2",
        city: "Durban", workMode: .remote, availability: .fullYear,
        bio: "Research-minded systems student. Prefers evidence over opinion.",
        skills: [
            StudentSkill(name: "Figma", category: .design, proficiency: .intermediate),
            StudentSkill(name: "Prototyping", category: .design, proficiency: .intermediate),
            StudentSkill(name: "Teamwork", category: .communication, proficiency: .advanced,
                         evidence: "Co-ran a six-person capstone studio"),
            StudentSkill(name: "User research", category: .research, proficiency: .intermediate),
        ],
        interests: ["Product Design", "Data"],
        projects: [
            Project(title: "User research portfolio",
                    summary: "Five studies on campus services with synthesised findings",
                    outcome: "Two recommendations adopted by student services", year: 2026),
        ],
        cvFileName: "Maya_Chen_CV.pdf", profileStrength: 84, advisor: "Thabo Mokoena")

    static let sipho = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000004")!,
        fullName: "Sipho Dlamini", initials: "SD", programme: "BTech Software Development", year: "Year 3",
        city: "Johannesburg", workMode: .hybrid, availability: .immediate,
        bio: "Back-end leaning developer who likes measurable work.",
        skills: [
            StudentSkill(name: "SwiftUI", category: .technology, proficiency: .advanced),
            StudentSkill(name: "Git", category: .technology, proficiency: .advanced),
            StudentSkill(name: "SQL", category: .data, proficiency: .intermediate),
        ],
        interests: ["Mobile", "Back-end"],
        projects: [],
        profileStrength: 61, advisor: "Thabo Mokoena")

    static let anele = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000005")!,
        fullName: "Anele Ndlovu", initials: "AN", programme: "BCom Informatics", year: "Year 2",
        city: "Durban", workMode: .onSite, availability: .undecided,
        bio: "Analytics student moving towards product work.",
        skills: [
            StudentSkill(name: "Excel", category: .data, proficiency: .advanced),
            StudentSkill(name: "SQL", category: .data, proficiency: .intermediate),
        ],
        interests: ["Data", "Business"],
        projects: [],
        profileStrength: 44, advisor: "Nomsa Dube")

    static let reece = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000006")!,
        fullName: "Reece Adams", initials: "RA", programme: "BSc Product Design", year: "Year 1",
        city: "Cape Town", workMode: .remote, availability: .undecided,
        bio: "First-year design student, still exploring.",
        skills: [StudentSkill(name: "Figma", category: .design, proficiency: .beginner)],
        interests: ["Product Design"],
        projects: [],
        profileStrength: 22, advisor: "Nomsa Dube")

    static let students: [Student] = [alex, jordan, maya, sipho, anele, reece]

    // MARK: Applications

    static let applications: [Application] = [
        Application(
            internshipID: productDesignIntern.id, studentID: alex.id, stage: .interviewScheduled,
            submittedDate: days(-8), lastUpdateDate: hours(-20), interviewDate: days(3),
            employerNote: "Resume viewed yesterday",
            nextAction: "Prep for interview",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-8)),
                TimelineEvent(title: "Reviewed by Orbit Labs", detail: "Resume viewed", date: days(-2)),
                TimelineEvent(title: "Interview scheduled", detail: "Thursday · 30 min · Teams", date: days(3), isDone: false),
            ]),
        Application(
            internshipID: mobileDevIntern.id, studentID: alex.id, stage: .underReview,
            submittedDate: days(-5), lastUpdateDate: days(-1),
            employerNote: "Resume viewed yesterday", nextAction: "View details",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-5)),
                TimelineEvent(title: "Under review", detail: "With the mobile guild lead", date: days(-1)),
            ]),
        Application(
            internshipID: dataAnalystIntern.id, studentID: alex.id, stage: .shortlisted,
            submittedDate: days(-12), lastUpdateDate: days(-3),
            employerNote: "Shortlisted by 2 reviewers", nextAction: "Take assessment",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-12)),
                TimelineEvent(title: "Under review", date: days(-9)),
                TimelineEvent(title: "Shortlisted", detail: "2 of 11 reviewers flagged you", date: days(-3)),
            ]),
    ]

    static let savedSearches: [SavedSearch] = [
        SavedSearch(label: "Product design · Remote · Paid",
                    filters: ["Internship", "Remote", "Paid"], alertsEnabled: true),
    ]

    // MARK: Candidate pipeline (employer view)

    static func candidate(_ student: Student, internship: Internship, status: ApplicationStage) -> Candidate {
        let evidence = student.projects.first.flatMap { project in
            project.outcome.map { "\(project.title): \($0)" }
        } ?? student.skills.first?.evidence ?? "\(student.programme) · \(student.year)"
        return Candidate(internshipID: internship.id,
                         student: student,
                         match: MatchEngine.shared.score(for: student, on: internship),
                         status: status,
                         evidence: evidence,
                         availableFrom: student.availability.rawValue)
    }

    static func candidates(for internship: Internship) -> [Candidate] {
        [
            candidate(jordan, internship: internship, status: .interviewScheduled),
            candidate(maya, internship: internship, status: .underReview),
            candidate(alex, internship: internship, status: .shortlisted),
            candidate(sipho, internship: internship, status: .submitted),
            candidate(anele, internship: internship, status: .submitted),
            candidate(reece, internship: internship, status: .submitted),
        ].sorted { $0.match > $1.match }
    }

    // MARK: Messages

    static let threads: [MessageThread] = {
        let orbitThread = UUID()
        let northstarThread = UUID()
        return [
            MessageThread(id: orbitThread, participantName: "Priya Naidoo", participantInitials: "PN",
                          context: "Product Design Intern · Orbit Labs",
                          messages: [
                              Message(threadID: orbitThread, body: "Hi Alex — we liked your campus events app. "
                                      + "Can we book 30 minutes this week?", sentAt: hours(-26), fromCurrentUser: false),
                              Message(threadID: orbitThread, body: "Thursday after 10:00 works for me.",
                                      sentAt: hours(-24), fromCurrentUser: true),
                              Message(threadID: orbitThread, body: "Perfect. Calendar invite on its way — bring "
                                      + "one project you would walk us through.", sentAt: hours(-20), fromCurrentUser: false),
                          ], unread: 2),
            MessageThread(id: northstarThread, participantName: "Daniel Venter", participantInitials: "DV",
                          context: "Mobile Developer Intern · Northstar Labs",
                          messages: [
                              Message(threadID: northstarThread, body: "Your accessibility audit note caught our eye. "
                                      + "Which app did you audit?", sentAt: days(-2), fromCurrentUser: false),
                              Message(threadID: northstarThread, body: "The campus transport app — 18 issues, 11 fixed upstream.",
                                      sentAt: days(-2), fromCurrentUser: true),
                          ]),
        ]
    }()

    // MARK: Programme (manager view)

    static let placements: [Placement] = [
        Placement(studentID: jordan.id, studentName: jordan.fullName, initials: jordan.initials,
                  stage: .interviewing, readiness: 92, topSkills: jordan.skillNames, advisor: "Nomsa Dube",
                  internshipTitle: "Product Design Intern"),
        Placement(studentID: maya.id, studentName: maya.fullName, initials: maya.initials,
                  stage: .shortlisted, readiness: 84, topSkills: maya.skillNames, advisor: "Thabo Mokoena",
                  internshipTitle: "Product Design Intern"),
        Placement(studentID: alex.id, studentName: alex.fullName, initials: alex.initials,
                  stage: .applying, readiness: 78, topSkills: alex.skillNames, advisor: "Nomsa Dube",
                  internshipTitle: "Mobile Developer Intern"),
        Placement(studentID: sipho.id, studentName: sipho.fullName, initials: sipho.initials,
                  stage: .preparing, readiness: 61, topSkills: sipho.skillNames, advisor: "Thabo Mokoena"),
        Placement(studentID: anele.id, studentName: anele.fullName, initials: anele.initials,
                  stage: .preparing, readiness: 44, topSkills: anele.skillNames, advisor: "Nomsa Dube"),
        Placement(studentID: reece.id, studentName: reece.fullName, initials: reece.initials,
                  stage: .preparing, readiness: 22, topSkills: reece.skillNames, advisor: "Thabo Mokoena"),
    ]

    static let metrics = ProgramMetrics(totalStudents: 248, readyForPlacement: 96,
                                        activeApplications: 412, successfulPlacements: 63, unmatchedStudents: 41)

    static let readiness: [ReadinessSlice] = [
        ReadinessSlice(band: .readyToApply, count: 96),
        ReadinessSlice(band: .nearlyReady, count: 74),
        ReadinessSlice(band: .needsSupport, count: 37),
        ReadinessSlice(band: .notStarted, count: 41),
    ]

    /// Applications sent per week over the current cycle, oldest first.
    static let weeklyApplications: [Int] = [26, 31, 44, 38, 57, 63, 71]

    static let alerts: [ReportAlert] = [
        ReportAlert(kind: .noApplications, title: "37 students have sent zero applications",
                    detail: "All have profiles above 60% and are eligible for 4+ open roles",
                    action: "Nudge cohort", studentCount: 37),
        ReportAlert(kind: .incompleteProfile, title: "12 profiles block matching",
                    detail: "Missing CV or evidenced skills — matches cannot be explained without them",
                    action: "Request evidence", studentCount: 12),
        ReportAlert(kind: .deadlineSoon, title: "UX Research Intern closes in 3 days",
                    detail: "9 eligible students have not applied yet",
                    action: "Notify eligible", studentCount: 9),
        ReportAlert(kind: .awaitingEmployer, title: "6 applications awaiting employer response",
                    detail: "Oldest has been open 14 days against a 5-day service level",
                    action: "Chase employers"),
        ReportAlert(kind: .missingDocumentation, title: "4 placements need paperwork",
                    detail: "Signed work-placement agreements outstanding before start dates",
                    action: "Send for signature", studentCount: 4),
    ]

    static let skillCatalogue: [Skill] = [
        Skill(name: "Figma", category: .design), Skill(name: "Prototyping", category: .design),
        Skill(name: "Design systems", category: .design), Skill(name: "Accessibility", category: .design),
        Skill(name: "User research", category: .research), Skill(name: "Interviewing", category: .research),
        Skill(name: "Synthesis", category: .research),
        Skill(name: "SwiftUI", category: .technology), Skill(name: "Swift", category: .technology),
        Skill(name: "Git", category: .technology), Skill(name: "Xcode", category: .technology),
        Skill(name: "Combine", category: .technology), Skill(name: "REST APIs", category: .technology),
        Skill(name: "SQL", category: .data), Skill(name: "Python", category: .data),
        Skill(name: "Dashboards", category: .data), Skill(name: "Statistics", category: .data),
        Skill(name: "Excel", category: .data),
        Skill(name: "Communication", category: .communication), Skill(name: "Copywriting", category: .communication),
        Skill(name: "Teamwork", category: .communication),
    ]
}
