package qa.udst.coworkhub.controller;

import qa.udst.coworkhub.service.BookingService;
import qa.udst.coworkhub.entity.BookableResource;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;

@RestController 
@RequestMapping("/api/resources/available")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class AvailabilityController {
    private final BookingService bookingService;

    @GetMapping
    public ResponseEntity<List<BookableResource>> getAvailable(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        return ResponseEntity.ok(bookingService.getAvailableResources(start, end));
    }    
}
