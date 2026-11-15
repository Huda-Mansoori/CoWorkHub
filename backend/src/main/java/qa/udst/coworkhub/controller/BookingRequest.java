package qa.udst.coworkhub.controller;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class BookingRequest {

    private Long memberId;
    private Long resourceId;
    private LocalDateTime startDateTime;
    private LocalDateTime endDateTime;
    private Integer attendees;
    private String status;  // only used when cancelling
}