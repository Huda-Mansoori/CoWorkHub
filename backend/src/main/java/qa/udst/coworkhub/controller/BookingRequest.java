package qa.udst.coworkhub.controller;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter 
public class BookingRequest {
    private Long resourceId;
    private Long memberId;
    private String startDateTime;
    private String endDateTime;
    private Integer attendees;
    private String status; // when cancelling
}
