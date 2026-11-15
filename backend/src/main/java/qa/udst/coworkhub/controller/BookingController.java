package qa.udst.coworkhub.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import lombok.RequiredArgsConstructor;
import qa.udst.coworkhub.entity.Booking;
import qa.udst.coworkhub.service.BookingService;

@RestController 
@RequestMapping("/api/bookings")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class BookingController {
    private final BookingService bookingService;

    // get all bookings
    @GetMapping
    public ResponseEntity<List<Booking>> getAllBookings() {
        return ResponseEntity.ok(bookingService.getAllBookings());
    }

    // get bookings of a member
    @GetMapping("/member/{memberId}")
    public ResponseEntity<List<Booking>> getMemberBookings(
            @PathVariable Long memberId) {
        return ResponseEntity.ok(bookingService.getBookingsByMember(memberId));
    }

    // create booking
    @PostMapping
    public ResponseEntity<Booking> createBooking(@RequestBody BookingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(bookingService.createBooking(request));
    }
    
    // update booking
    @PutMapping("/{id}")
    public ResponseEntity<Booking> updateBooking(
            @PathVariable Long id,
            @RequestBody BookingRequest request) {
        return ResponseEntity.ok(bookingService.updateBooking(id, request));
    }
}
