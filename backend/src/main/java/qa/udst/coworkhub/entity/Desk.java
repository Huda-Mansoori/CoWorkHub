package qa.udst.coworkhub.entity;

import java.math.BigDecimal;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;

@Entity
public class Desk extends BookableResource {

    @Column(nullable = false, length = 50)
    private String deskType;

    public Desk() {
    }

    public Desk(String name, String location,
                Integer capacity, BigDecimal hourlyRate,
                ResourceStatus status, String deskType) {

        super(name, location, capacity, hourlyRate, status);
        this.deskType = deskType;
    }

    public String getDeskType() {
        return deskType;
    }

    public void setDeskType(String deskType) {
        this.deskType = deskType;
    }
}