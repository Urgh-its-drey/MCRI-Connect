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

    /// Auth uids the debug workspace seeds sign in as, so previews have an employer and a
    /// manager identity that resolves against the rows below.
    static let employerAccountID = UUID(uuidString: "D0000000-0000-0000-0000-000000000001")!
    static let managerAccountID = UUID(uuidString: "D0000000-0000-0000-0000-000000000002")!

    static let orbitLabs = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
                                   name: "Orbit Labs", initials: "O",
                                   tagline: "Product studios for health and finance",
                                   website: "https://orbitlabs.co.za", location: "Cape Town",
                                   registrationNumber: "2016/442187/07",
                                   teamLabel: "Product guild · 2 open roles", openRoles: 2,
                                   isVerified: true, hiredLastCycle: 6)
    static let northstar = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
                                   name: "Northstar Labs", initials: "N",
                                   tagline: "Mobile guild building banking apps",
                                   website: "https://northstarlabs.io", location: "Cape Town",
                                   registrationNumber: "2019/118042/07",
                                   teamLabel: "Mobile guild · 2 open roles", openRoles: 2,
                                   isVerified: true, hiredLastCycle: 3)
    static let mcriAnalytics = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003")!,
                                       name: "MCRI Analytics", initials: "M",
                                       tagline: "Data practice for public-sector programmes",
                                       website: "https://mcrianalytics.org.za", location: "Durban",
                                       registrationNumber: "2014/776120/07",
                                       teamLabel: "Data practice · 2 open roles", openRoles: 2,
                                       isVerified: true, hiredLastCycle: 4)
    static let vantageHealth = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000004")!,
                                       name: "Vantage Health", initials: "V",
                                       tagline: "Clinic software used by 400 facilities",
                                       website: "https://vantagehealth.co.za", location: "Remote · Cape Town",
                                       registrationNumber: "2015/123456/07",
                                       teamLabel: "Product · 1 open role", openRoles: 1,
                                       isVerified: true, hiredLastCycle: 2)
    static let kasiFintech = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000005")!,
                                     name: "Kasi Fintech", initials: "K",
                                     tagline: "Savings products for township economies",
                                     website: "https://kasifintech.co.za", location: "Johannesburg",
                                     registrationNumber: "2020/987654/07",
                                     teamLabel: "Growth · 1 open role", openRoles: 1,
                                     isVerified: true, hiredLastCycle: 5)
    static let capeFintechCollective = Company(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000006")!,
                                               name: "Cape Fintech Collective", initials: "C",
                                               tagline: "Early-stage fintech network and shared back-office",
                                               website: "https://capefintech.org.za", location: "Cape Town",
                                               registrationNumber: "2022/456789/07",
                                               teamLabel: "Operations · Pending review", openRoles: 0,
                                               isVerified: false, hiredLastCycle: 0)

    static let companies: [Company] = [orbitLabs, northstar, mcriAnalytics, vantageHealth, kasiFintech, capeFintechCollective]

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
        applicants: 4, teamSize: 6, category: .design)

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
        applicants: 4, teamSize: 5, category: .technology)

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
        applicants: 2, teamSize: 6, category: .data)

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
        applicants: 3, teamSize: 3, category: .research)

    static let growthMarketingIntern = Internship(
        id: UUID(uuidString: "B0000000-0000-0000-0000-000000000005")!,
        title: "Growth Marketing Intern", companyID: kasiFintech.id, companyName: kasiFintech.name,
        companyInitials: kasiFintech.initials, location: "Johannesburg", workMode: .hybrid,
        durationWeeks: 12, compensation: "R8 500 / month", isPaid: true, easyApply: true,
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
        applicants: 1, teamSize: 4, category: .business)

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
        applicants: 3, teamSize: 8, category: .technology)

    static let dataEngineeringIntern = Internship(
        id: UUID(uuidString: "B0000000-0000-0000-0000-000000000007")!,
        title: "Data Engineering Intern", companyID: mcriAnalytics.id, companyName: mcriAnalytics.name,
        companyInitials: mcriAnalytics.initials, location: "Remote · South Africa", workMode: .remote,
        durationWeeks: 16, compensation: "R16 000 / month", isPaid: true, easyApply: true,
        postedDate: days(-11), closingDate: days(18),
        description: "Build and maintain the data pipelines that feed the placement analytics warehouse, "
            + "working with the analytics lead on scheduling, observability and quality checks.",
        responsibilities: [
            "Write Python ETL jobs for new data sources",
            "Add data quality checks with Great Expectations",
            "Document pipeline lineage for downstream dashboards",
        ],
        requiredSkills: ["Python", "SQL", "Git"],
        preferredSkills: ["Docker", "Airflow", "Dashboards"],
        careerInterests: ["Data", "Analytics"],
        applicants: 1, teamSize: 5, category: .data)

    static let uiuxDesignIntern = Internship(
        id: UUID(uuidString: "B0000000-0000-0000-0000-000000000008")!,
        title: "UI/UX Design Intern", companyID: northstar.id, companyName: northstar.name,
        companyInitials: northstar.initials, location: "Cape Town", workMode: .hybrid,
        durationWeeks: 12, compensation: "R13 000 / month", isPaid: true, easyApply: true,
        postedDate: days(-5), closingDate: days(16),
        description: "Design mobile-first flows for the Northstar banking app, from wireframes through "
            + "high-fidelity UI, working closely with the mobile guild and design system lead.",
        responsibilities: [
            "Translate research insights into wireframes and flows",
            "Produce high-fidelity UI in Figma using the design system",
            "Prepare hand-off specs and attend design QA",
        ],
        requiredSkills: ["Figma", "Prototyping", "Communication"],
        preferredSkills: ["Design systems", "Accessibility", "SwiftUI"],
        careerInterests: ["Product Design", "Front-end"],
        applicants: 0, teamSize: 4, category: .design)

    static let internships: [Internship] = [
        productDesignIntern, mobileDevIntern, dataAnalystIntern, healthUXIntern,
        growthMarketingIntern, backendIntern, dataEngineeringIntern, uiuxDesignIntern,
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

    static let thandiwe = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000007")!,
        fullName: "Thandiwe Molefe", initials: "TM", programme: "BSc Computer Science", year: "Year 3",
        city: "Cape Town", workMode: .hybrid, availability: .juneWindow,
        bio: "Full-stack curious computer scientist with a strong systems and algorithms foundation.",
        skills: [
            StudentSkill(name: "Swift", category: .technology, proficiency: .advanced,
                         evidence: "Built a distributed key-value store coursework in Swift"),
            StudentSkill(name: "PostgreSQL", category: .data, proficiency: .advanced,
                         evidence: "Designed schema and queries for a 50k-row assignment dataset"),
            StudentSkill(name: "REST APIs", category: .technology, proficiency: .advanced),
            StudentSkill(name: "Git", category: .technology, proficiency: .advanced),
            StudentSkill(name: "Unit testing", category: .technology, proficiency: .intermediate),
            StudentSkill(name: "Docker", category: .technology, proficiency: .intermediate),
        ],
        interests: ["Back-end", "Mobile"],
        projects: [
            Project(title: "Campus shuttle tracker",
                    summary: "Real-time bus location app with a Vapor back end",
                    outcome: "Reduced average wait-time complaints by 30% in a pilot", year: 2026),
        ],
        cvFileName: "Thandiwe_Molefe_CV.pdf", profileStrength: 88, advisor: "Thabo Mokoena")

    static let lwazi = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000008")!,
        fullName: "Lwazi Nkosi", initials: "LN", programme: "BSc Data Science", year: "Year 3",
        city: "Durban", workMode: .remote, availability: .fullYear,
        bio: "Data scientist in training who turns messy public data into clean, actionable dashboards.",
        skills: [
            StudentSkill(name: "Python", category: .data, proficiency: .advanced,
                         evidence: "Won a faculty datathon with a churn model in scikit-learn"),
            StudentSkill(name: "SQL", category: .data, proficiency: .advanced),
            StudentSkill(name: "Dashboards", category: .data, proficiency: .advanced,
                         evidence: "Built a Streamlit dashboard used by a student NGO"),
            StudentSkill(name: "Statistics", category: .data, proficiency: .intermediate),
            StudentSkill(name: "Git", category: .technology, proficiency: .intermediate),
        ],
        interests: ["Data", "Analytics"],
        projects: [
            Project(title: "Municipal spend dashboard",
                    summary: "Open-data dashboard tracking procurement in KwaZulu-Natal",
                    outcome: "Featured in a student data-journalism piece", year: 2025),
        ],
        cvFileName: "Lwazi_Nkosi_CV.pdf", profileStrength: 75, advisor: "Thabo Mokoena")

    static let emma = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000009")!,
        fullName: "Emma Patel", initials: "EP", programme: "BA Strategic Communication", year: "Year 2",
        city: "Johannesburg", workMode: .hybrid, availability: .juneWindow,
        bio: "Strategic communicator who enjoys writing, campaign analytics and audience research.",
        skills: [
            StudentSkill(name: "Copywriting", category: .communication, proficiency: .advanced,
                         evidence: "Wrote copy for a student society campaign that reached 5 000 people"),
            StudentSkill(name: "Analytics", category: .data, proficiency: .intermediate,
                         evidence: "Tracked Meta campaign metrics for two student clients"),
            StudentSkill(name: "Excel", category: .data, proficiency: .advanced),
            StudentSkill(name: "Communication", category: .communication, proficiency: .advanced),
        ],
        interests: ["Marketing", "Business"],
        projects: [
            Project(title: "Mental-health awareness campaign",
                    summary: "Cross-platform campaign for student counselling services",
                    outcome: "Raised booking enquiries by 40% over two weeks", year: 2026),
        ],
        cvFileName: "Emma_Patel_CV.pdf", profileStrength: 68, advisor: "Nomsa Dube")

    static let daniel = Student(
        id: UUID(uuidString: "C0000000-0000-0000-0000-000000000010")!,
        fullName: "Daniel Okonkwo", initials: "DO", programme: "BTech Software Development", year: "Year 2",
        city: "Johannesburg", workMode: .remote, availability: .immediate,
        bio: "Self-taught mobile developer with a focus on clean architecture and accessible interfaces.",
        skills: [
            StudentSkill(name: "SwiftUI", category: .technology, proficiency: .intermediate,
                         evidence: "Published a habit-tracking app on the App Store"),
            StudentSkill(name: "Git", category: .technology, proficiency: .intermediate),
            StudentSkill(name: "Xcode", category: .technology, proficiency: .intermediate),
            StudentSkill(name: "Accessibility", category: .design, proficiency: .beginner),
        ],
        interests: ["Mobile", "Front-end"],
        projects: [
            Project(title: "Habit tracker",
                    summary: "iOS habit tracker with widgets and local notifications",
                    outcome: "100 downloads in the first month", year: 2026),
        ],
        cvFileName: "Daniel_Okonkwo_CV.pdf", profileStrength: 55, advisor: "Thabo Mokoena")

    static let students: [Student] = [
        alex, jordan, maya, sipho, anele, reece, thandiwe, lwazi, emma, daniel,
    ]

    // MARK: Applications

    static let applications: [Application] = [
        // Alex
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
            employerNote: "Portfolio passed to mobile guild lead", nextAction: "View details",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-5)),
                TimelineEvent(title: "Under review", detail: "With the mobile guild lead", date: days(-1)),
            ]),

        // Jordan
        Application(
            internshipID: productDesignIntern.id, studentID: jordan.id, stage: .offered,
            submittedDate: days(-18), lastUpdateDate: hours(-4),
            employerNote: "Offer approved by hiring manager", nextAction: "Accept or decline offer",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-18)),
                TimelineEvent(title: "Reviewed by Orbit Labs", detail: "Portfolio reviewed", date: days(-14)),
                TimelineEvent(title: "Shortlisted", detail: "Top pick by design lead", date: days(-10)),
                TimelineEvent(title: "Interview completed", detail: "Panel interview · 45 min", date: days(-5)),
                TimelineEvent(title: "Offer sent", detail: "R14 000 / month · 12 weeks", date: hours(-4), isDone: false),
            ]),
        Application(
            internshipID: healthUXIntern.id, studentID: jordan.id, stage: .interviewScheduled,
            submittedDate: days(-6), lastUpdateDate: days(-1), interviewDate: days(4),
            employerNote: "Second choice backup role",
            nextAction: "Confirm interview slot",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-6)),
                TimelineEvent(title: "Interview scheduled", detail: "Friday · 45 min · Zoom", date: days(4), isDone: false),
            ]),

        // Maya
        Application(
            internshipID: productDesignIntern.id, studentID: maya.id, stage: .underReview,
            submittedDate: days(-4), lastUpdateDate: days(-2),
            employerNote: "Strong research background", nextAction: "Review portfolio",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-4)),
                TimelineEvent(title: "Under review", detail: "Portfolio with research focus", date: days(-2)),
            ]),
        Application(
            internshipID: healthUXIntern.id, studentID: maya.id, stage: .shortlisted,
            submittedDate: days(-10), lastUpdateDate: days(-3),
            employerNote: "Shortlisted for research skills", nextAction: "Take assessment",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-10)),
                TimelineEvent(title: "Under review", date: days(-7)),
                TimelineEvent(title: "Shortlisted", detail: "Research portfolio stood out", date: days(-3)),
            ]),

        // Sipho
        Application(
            internshipID: mobileDevIntern.id, studentID: sipho.id, stage: .interviewScheduled,
            submittedDate: days(-7), lastUpdateDate: days(-1), interviewDate: days(2),
            employerNote: "SwiftUI experience matches role",
            nextAction: "Prepare technical screen",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-7)),
                TimelineEvent(title: "Interview scheduled", detail: "Wednesday · 45 min · Google Meet", date: days(2), isDone: false),
            ]),
        Application(
            internshipID: backendIntern.id, studentID: sipho.id, stage: .underReview,
            submittedDate: days(-3), lastUpdateDate: days(-1),
            employerNote: "Back-end leaning profile", nextAction: "View details",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-3)),
                TimelineEvent(title: "Under review", detail: "With the platform team", date: days(-1)),
            ]),

        // Thandiwe
        Application(
            internshipID: backendIntern.id, studentID: thandiwe.id, stage: .shortlisted,
            submittedDate: days(-11), lastUpdateDate: days(-2),
            employerNote: "Top technical match for backend role", nextAction: "Schedule interview",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-11)),
                TimelineEvent(title: "Under review", detail: "Technical screen passed", date: days(-5)),
                TimelineEvent(title: "Shortlisted", detail: "Highest match score", date: days(-2)),
            ]),
        Application(
            internshipID: mobileDevIntern.id, studentID: thandiwe.id, stage: .submitted,
            submittedDate: days(-4), lastUpdateDate: days(-4),
            employerNote: "Awaiting first review", nextAction: "Waiting",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-4)),
            ]),

        // Lwazi
        Application(
            internshipID: dataAnalystIntern.id, studentID: lwazi.id, stage: .interviewScheduled,
            submittedDate: days(-9), lastUpdateDate: days(-2), interviewDate: days(5),
            employerNote: "Strong SQL and dashboard evidence",
            nextAction: "Prepare case study",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-9)),
                TimelineEvent(title: "Interview scheduled", detail: "Monday · 30 min · Teams", date: days(5), isDone: false),
            ]),
        Application(
            internshipID: dataEngineeringIntern.id, studentID: lwazi.id, stage: .underReview,
            submittedDate: days(-6), lastUpdateDate: days(-3),
            employerNote: "Python pipeline project relevant", nextAction: "View details",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-6)),
                TimelineEvent(title: "Under review", detail: "Data engineering lead reviewing", date: days(-3)),
            ]),

        // Emma
        Application(
            internshipID: growthMarketingIntern.id, studentID: emma.id, stage: .submitted,
            submittedDate: days(-2), lastUpdateDate: days(-2),
            employerNote: "Awaiting first review", nextAction: "Waiting",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-2)),
            ]),
        Application(
            internshipID: healthUXIntern.id, studentID: emma.id, stage: .submitted,
            submittedDate: days(-5), lastUpdateDate: days(-5),
            employerNote: "Awaiting first review", nextAction: "Waiting",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-5)),
            ]),

        // Daniel
        Application(
            internshipID: mobileDevIntern.id, studentID: daniel.id, stage: .submitted,
            submittedDate: days(-3), lastUpdateDate: days(-3),
            employerNote: "Awaiting first review", nextAction: "Waiting",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-3)),
            ]),
        Application(
            internshipID: backendIntern.id, studentID: daniel.id, stage: .submitted,
            submittedDate: days(-6), lastUpdateDate: days(-6),
            employerNote: "Awaiting first review", nextAction: "Waiting",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-6)),
            ]),

        // Anele
        Application(
            internshipID: dataAnalystIntern.id, studentID: anele.id, stage: .submitted,
            submittedDate: days(-1), lastUpdateDate: days(-1),
            employerNote: "Awaiting first review", nextAction: "Waiting",
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-1)),
            ]),

        // Reece
        Application(
            internshipID: productDesignIntern.id, studentID: reece.id, stage: .declined,
            submittedDate: days(-12), lastUpdateDate: days(-10),
            employerNote: "Profile too early in programme", nextAction: nil,
            timeline: [
                TimelineEvent(title: "Application submitted", date: days(-12)),
                TimelineEvent(title: "Not progressed", detail: "Advised to re-apply next cycle", date: days(-10)),
            ]),
    ]

    static let savedSearches: [SavedSearch] = [
        SavedSearch(label: "Product design · Remote · Paid",
                    filters: ["Internship", "Remote", "Paid"], alertsEnabled: true),
        SavedSearch(label: "Data · Durban · Full year",
                    filters: ["Internship", "Data", "Durban", "Full academic year"]),
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

    /// Build the employer pipeline directly from applications so every candidate has a matching
    /// application row and the dashboard captions stay consistent.
    static func candidates(for internship: Internship) -> [Candidate] {
        applications
            .filter { $0.internshipID == internship.id && $0.stage != .declined }
            .compactMap { app in
                students.first { $0.id == app.studentID }.map {
                    candidate($0, internship: internship, status: app.stage)
                }
            }
            .sorted { $0.match > $1.match }
    }

    // MARK: Messages

    static let threads: [MessageThread] = {
        let orbitThread = UUID(uuidString: "E0000000-0000-0000-0000-000000000001")!
        let northstarThread = UUID(uuidString: "E0000000-0000-0000-0000-000000000002")!
        let vantageThread = UUID(uuidString: "E0000000-0000-0000-0000-000000000003")!
        let mcriThread = UUID(uuidString: "E0000000-0000-0000-0000-000000000004")!
        return [
            MessageThread(id: orbitThread, participantID: employerAccountID,
                          participantName: "Priya Naidoo", participantInitials: "PN",
                          context: "Product Design Intern · Orbit Labs",
                          messages: [
                              Message(threadID: orbitThread, body: "Hi Alex — we loved your campus events app. "
                                      + "Can we book 30 minutes this week?", sentAt: hours(-26), fromCurrentUser: false),
                              Message(threadID: orbitThread, body: "Thursday after 10:00 works for me.",
                                      sentAt: hours(-24), fromCurrentUser: true),
                              Message(threadID: orbitThread, body: "Perfect. Calendar invite on its way — bring "
                                      + "one project you would walk us through.", sentAt: hours(-20), fromCurrentUser: false),
                          ], unread: 2),
            MessageThread(id: northstarThread, participantID: employerAccountID,
                          participantName: "Daniel Venter", participantInitials: "DV",
                          context: "Mobile Developer Intern · Northstar Labs",
                          messages: [
                              Message(threadID: northstarThread, body: "Your SwiftUI portfolio caught our eye. "
                                      + "Which app are you most proud of?", sentAt: days(-2), fromCurrentUser: false),
                              Message(threadID: northstarThread, body: "The campus transport app — 18 accessibility issues, 11 fixed upstream.",
                                      sentAt: days(-2), fromCurrentUser: true),
                              Message(threadID: northstarThread, body: "Great attention to detail. Let's talk through it on Wednesday.",
                                      sentAt: hours(-8), fromCurrentUser: false),
                          ], unread: 1),
            MessageThread(id: vantageThread, participantID: employerAccountID,
                          participantName: "Dr. Sarah Mbeki", participantInitials: "SM",
                          context: "UX Research Intern · Vantage Health",
                          messages: [
                              Message(threadID: vantageThread, body: "Hi Maya — your research portfolio is a strong match. "
                                      + "Are you comfortable conducting hospital-site interviews?", sentAt: hours(-12), fromCurrentUser: false),
                              Message(threadID: vantageThread, body: "Yes, I have ethics clearance from last year's campus services study.",
                                      sentAt: hours(-10), fromCurrentUser: true),
                              Message(threadID: vantageThread, body: "Excellent. We'll send the short assessment today.",
                                      sentAt: hours(-9), fromCurrentUser: false),
                          ], unread: 2),
            MessageThread(id: mcriThread, participantID: managerAccountID,
                          participantName: "Thabo Mokoena", participantInitials: "TM",
                          context: "Data Analyst Intern · MCRI Analytics",
                          messages: [
                              Message(threadID: mcriThread, body: "Lwazi, well done on the municipal spend dashboard. "
                                      + "Can you share the SQL behind it?", sentAt: days(-1), fromCurrentUser: false),
                              Message(threadID: mcriThread, body: "Sure — I'll send the repo link and a short write-up.",
                                      sentAt: hours(-20), fromCurrentUser: true),
                          ]),
        ]
    }()

    // MARK: Programme (manager view)

    static let placements: [Placement] = [
        Placement(studentID: jordan.id, studentName: jordan.fullName, initials: jordan.initials,
                  stage: .placed, readiness: 92, topSkills: jordan.skillNames, advisor: "Nomsa Dube",
                  internshipTitle: "Product Design Intern · Orbit Labs"),
        Placement(studentID: maya.id, studentName: maya.fullName, initials: maya.initials,
                  stage: .interviewing, readiness: 84, topSkills: maya.skillNames, advisor: "Thabo Mokoena",
                  internshipTitle: "UX Research Intern · Vantage Health"),
        Placement(studentID: alex.id, studentName: alex.fullName, initials: alex.initials,
                  stage: .applying, readiness: 78, topSkills: alex.skillNames, advisor: "Nomsa Dube",
                  internshipTitle: "Mobile Developer Intern · Northstar Labs"),
        Placement(studentID: thandiwe.id, studentName: thandiwe.fullName, initials: thandiwe.initials,
                  stage: .shortlisted, readiness: 88, topSkills: thandiwe.skillNames, advisor: "Thabo Mokoena",
                  internshipTitle: "Backend Engineering Intern · Orbit Labs"),
        Placement(studentID: lwazi.id, studentName: lwazi.fullName, initials: lwazi.initials,
                  stage: .interviewing, readiness: 75, topSkills: lwazi.skillNames, advisor: "Thabo Mokoena",
                  internshipTitle: "Data Analyst Intern · MCRI Analytics"),
        Placement(studentID: sipho.id, studentName: sipho.fullName, initials: sipho.initials,
                  stage: .applying, readiness: 61, topSkills: sipho.skillNames, advisor: "Thabo Mokoena",
                  internshipTitle: "Backend Engineering Intern · Orbit Labs"),
        Placement(studentID: emma.id, studentName: emma.fullName, initials: emma.initials,
                  stage: .preparing, readiness: 68, topSkills: emma.skillNames, advisor: "Nomsa Dube"),
        Placement(studentID: daniel.id, studentName: daniel.fullName, initials: daniel.initials,
                  stage: .preparing, readiness: 55, topSkills: daniel.skillNames, advisor: "Thabo Mokoena"),
        Placement(studentID: anele.id, studentName: anele.fullName, initials: anele.initials,
                  stage: .preparing, readiness: 44, topSkills: anele.skillNames, advisor: "Nomsa Dube"),
        Placement(studentID: reece.id, studentName: reece.fullName, initials: reece.initials,
                  stage: .preparing, readiness: 22, topSkills: reece.skillNames, advisor: "Nomsa Dube"),
    ]

    /// Illustrative programme-wide numbers. The live `AppStore` recalculates these from the
    /// arrays above; the constants here show the intended scale of the demo dataset.
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
        Skill(name: "Docker", category: .technology), Skill(name: "Unit testing", category: .technology),
        Skill(name: "SQL", category: .data), Skill(name: "Python", category: .data),
        Skill(name: "Dashboards", category: .data), Skill(name: "Statistics", category: .data),
        Skill(name: "Excel", category: .data), Skill(name: "Data storytelling", category: .data),
        Skill(name: "Communication", category: .communication), Skill(name: "Copywriting", category: .communication),
        Skill(name: "Teamwork", category: .communication),
        Skill(name: "Analytics", category: .business),
    ]

    // MARK: Snapshot

    /// The same shape the Supabase snapshot returns, so previews and the local service
    /// exercise the real code path.
    static func snapshot(profile: ProfileRecord? = nil) -> DataSnapshot {
        DataSnapshot(
            students: students,
            companies: companies,
            internships: internships,
            applications: applications,
            placements: placements,
            threads: threads,
            savedSearches: savedSearches,
            savedRoleIDs: [productDesignIntern.id, backendIntern.id],
            candidates: internships.flatMap { candidates(for: $0) },
            profile: profile
        )
    }
}
