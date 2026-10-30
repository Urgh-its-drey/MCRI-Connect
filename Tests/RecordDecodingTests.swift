import Foundation

// Run with: swiftc MCRIConnect/Models/*.swift MCRIConnect/PreviewData/SampleData.swift \
// MCRIConnect/Services/MatchEngine.swift MCRIConnect/Services/DataService.swift \
// MCRIConnect/Services/SupabaseRecords.swift \
// Tests/RecordDecodingTests.swift -o /tmp/mcri-record-tests && /tmp/mcri-record-tests
@main
struct RecordDecodingTests {
    static func main() throws {
        let decoder = JSONDecoder()
        let id = UUID()
        let base: [String: Any] = [
            "id": id.uuidString, "full_name": "Nicole", "initials": NSNull(),
            "programme": "", "year": "", "city": "", "work_mode": "hybrid",
            "availability": "Not sure yet", "bio": "", "profile_strength": 0,
            "skills": [], "interests": [], "projects": [], "certificates": []
        ]
        for initials in [NSNull(), "", "NS"] as [Any] {
            var row = base
            row["initials"] = initials
            let data = try JSONSerialization.data(withJSONObject: row)
            let student = try decoder.decode(StudentRecordDTO.self, from: data).domain
            precondition(student.id == id)
            precondition(student.initials == (initials as? String == "NS" ? "NS" : "N"))
            precondition(student.skills.isEmpty && student.projects.isEmpty)

            row["application_id"] = UUID().uuidString
            row["internship_id"] = UUID().uuidString
            row["student_id"] = id.uuidString
            row["stage"] = "submitted"
            let candidate = try decoder.decode(CandidateRecordDTO.self,
                from: JSONSerialization.data(withJSONObject: row)).student(id: id)
            precondition(candidate.initials == student.initials)
        }
        let placement: [String: Any] = [
            "id": UUID().uuidString, "student_id": id.uuidString,
            "student_name": "Nicole", "initials": NSNull(), "stage": "preparing",
            "readiness": 0, "top_skills": []
        ]
        let decodedPlacement = try decoder.decode(PlacementRecordDTO.self,
            from: JSONSerialization.data(withJSONObject: placement)).domain
        precondition(decodedPlacement.initials == "N")

        let conversation: [String: Any] = [
            "id": UUID().uuidString, "subject": "Hello", "context": "", "unread": 0,
            "participant_id": id.uuidString, "participant_name": "Nicole",
            "participant_initials": NSNull(), "messages": []
        ]
        let thread = try decoder.decode(ConversationRecordDTO.self,
            from: JSONSerialization.data(withJSONObject: conversation)).domain
        precondition(thread.participantInitials == "N")
        print("Passed: new account, null/empty/populated initials, candidates, placements and conversations")
    }
}
