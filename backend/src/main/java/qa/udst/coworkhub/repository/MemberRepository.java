
package qa.udst.coworkhub.repository;

import qa.udst.coworkhub.entity.Member;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MemberRepository extends JpaRepository<Member, Long> {

    // Find a member by email
    Optional<Member> findByEmail(String email);

    // Check whether an email is already registered
    boolean existsByEmail(String email);
}
