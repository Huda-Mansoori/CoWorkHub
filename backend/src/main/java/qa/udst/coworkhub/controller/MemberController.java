
package qa.udst.coworkhub.controller;

import qa.udst.coworkhub.entity.Member;
import qa.udst.coworkhub.service.MemberService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/members")
@CrossOrigin(origins = "*")
public class MemberController {

    private final MemberService memberService;

    // Constructor injection
    public MemberController(MemberService memberService) {
        this.memberService = memberService;
    }

    // Get all members
    @GetMapping
    public ResponseEntity<List<Member>> getAllMembers() {
        return ResponseEntity.ok(memberService.getAllMembers());
    }

    // Get member by ID
    @GetMapping("/{id}")
    public ResponseEntity<Member> getMemberById(
            @PathVariable Long id) {
        return ResponseEntity.ok(memberService.getMemberById(id));
    }

    // Register a new member
    @PostMapping
    public ResponseEntity<Member> createMember(
            @RequestBody Member member) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(memberService.createMember(member));
    }

    // Update member details
    @PutMapping("/{id}")
    public ResponseEntity<Member> updateMember(
            @PathVariable Long id,
            @RequestBody Member member) {
        return ResponseEntity.ok(
                memberService.updateMember(id, member));
    }

    // Delete a member
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMember(
            @PathVariable Long id) {
        memberService.deleteMember(id);
        return ResponseEntity.noContent().build();
    }
}
