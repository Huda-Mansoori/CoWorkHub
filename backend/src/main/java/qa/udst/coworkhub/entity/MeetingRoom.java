
package qa.udst.coworkhub.entity;

import java.math.BigDecimal;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;

@Entity
public class MeetingRoom extends BookableResource {

    @Column(nullable = false)
    private Boolean projector;

    @Column(nullable = false)
    private Boolean videoConference;

    // Default constructor
    public MeetingRoom() {
    }

    // Parameterized constructor
    public MeetingRoom(String name, String location,
                       Integer capacity, BigDecimal hourlyRate,
                       ResourceStatus status, Boolean projector,
                       Boolean videoConference) {

        super(name, location, capacity, hourlyRate, status);
        this.projector = projector;
        this.videoConference = videoConference;
    }

    // Getters and Setters
    public Boolean getProjector() {
        return projector;
    }

    public void setProjector(Boolean projector) {
        this.projector = projector;
    }

    public Boolean getVideoConference() {
        return videoConference;
    }

    public void setVideoConference(Boolean videoConference) {
        this.videoConference = videoConference;
    }
}
