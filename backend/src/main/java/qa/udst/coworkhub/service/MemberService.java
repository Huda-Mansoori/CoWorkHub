
package qa.udst.coworkhub.service;

import qa.udst.coworkhub.entity.Member;
import qa.udst.coworkhub.repository.MemberRepository;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class MemberService {

    private final MemberRepository memberRepository;

    // Constructor injection
    public MemberService(MemberRepository memberRepository) {
        this.memberRepository = memberRepository;
    }

    // Get all members
    public List<Member> getAllMembers() {
        return memberRepository.findAll();
    }

    // Get member by ID
    public Member getMemberById(Long id) {
        return memberRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Member not found with ID: " + id
                ));
    }

    // Register a new member
    public Member createMember(Member member) {

        if (memberRepository.existsByEmail(member.getEmail())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "A member with this email already exists."
            );
        }

        return memberRepository.save(member);
    }

    // Update member details
    public Member updateMember(Long id, Member updatedMember) {

        Member existingMember = getMemberById(id);

        memberRepository.findByEmail(updatedMember.getEmail())
                .filter(member -> !member.getId().equals(id))
                .ifPresent(member -> {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "This email is already registered."
                    );
                });

        existingMember.setFullName(updatedMember.getFullName());
        existingMember.setEmail(updatedMember.getEmail());

        return memberRepository.save(existingMember);
    }

    // Delete member
    public void deleteMember(Long id) {
        Member member = getMemberById(id);

        if (!member.getBookings().isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Cannot delete a member who has booking records."
            );
        }

        memberRepository.delete(member);
    }
}
