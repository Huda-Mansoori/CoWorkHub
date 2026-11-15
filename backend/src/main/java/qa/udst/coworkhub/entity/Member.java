
package qa.udst.coworkhub.entity;

import jakarta.validation.constraints.*;
import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;

@Entity
@Table(name = "member")
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    @NotBlank
    @Size(max = 150)
    private String fullName;

    @Column(nullable = false, unique = true, length = 150)
    @NotBlank
    @Email
    @Size(max = 150)
    private String email;

    @JsonIgnore
    @OneToMany(mappedBy = "member")
    private List<Booking> bookings = new ArrayList<>();

    // Default constructor
    public Member() {
    }

    // Parameterized constructor
    public Member(String fullName, String email) {
        this.fullName = fullName;
        this.email = email;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public List<Booking> getBookings() {
        return bookings;
    }
}
