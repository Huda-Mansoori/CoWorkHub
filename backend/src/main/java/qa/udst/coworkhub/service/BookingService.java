package qa.udst.coworkhub.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import lombok.RequiredArgsConstructor;
import qa.udst.coworkhub.controller.BookingRequest;
import qa.udst.coworkhub.entity.BookableResource;
import qa.udst.coworkhub.entity.Booking;
import qa.udst.coworkhub.entity.BookingStatus;
import qa.udst.coworkhub.entity.Desk;
import qa.udst.coworkhub.entity.MeetingRoom;
import qa.udst.coworkhub.entity.Member;
import qa.udst.coworkhub.entity.ResourceStatus;
import qa.udst.coworkhub.repository.BookingRepository;
import qa.udst.coworkhub.repository.MemberRepository;
import qa.udst.coworkhub.repository.ResourceRepository;

@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final MemberRepository memberRepository;
    private final ResourceRepository resourceRepository;

    public Booking createBooking(BookingRequest request) {

        // 1. find member and resource by ID sent
        Member member = memberRepository.findById(request.getMemberId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Member not found with ID: " + request.getMemberId()
                ));

        BookableResource resource = resourceRepository.findById(request.getResourceId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Resource not found with ID: " + request.getResourceId()
                ));

        // 2. check business rules
        checkRules(resource, request, null);

        // 3. build and save booking
        Booking booking = new Booking();
        booking.setMember(member);
        booking.setResource(resource);
        booking.setStartDateTime(request.getStartDateTime());
        booking.setEndDateTime(request.getEndDateTime());
        booking.setAttendees(request.getAttendees());
        booking.setStatus(BookingStatus.CONFIRMED);
        booking.setTotalCost(calculateCost(resource, request.getStartDateTime(), request.getEndDateTime()));

        return bookingRepository.save(booking);
    }

    public List<Booking> getAllBookings() {
        return bookingRepository.findAll();
    }

    private void checkRules(BookableResource resource, BookingRequest request, Long bookingId) {

        // check required fields
        if (request.getStartDateTime() == null || request.getEndDateTime() == null
                || request.getAttendees() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Start time, end time and attendees are required."
            );
        }

        // if bookings overlap
        boolean overlap;
        if (bookingId == null) {
            overlap = bookingRepository.hasOverlappingBooking(
                    resource.getId(),
                    BookingStatus.CONFIRMED,
                    request.getStartDateTime(),
                    request.getEndDateTime());
        } else {
            overlap = bookingRepository.hasOverlappingBookingExcludingCurrent(
                    resource.getId(),
                    BookingStatus.CONFIRMED,
                    request.getStartDateTime(),
                    request.getEndDateTime(),
                    bookingId);
        }
        if (overlap) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "This resource is already booked for the selected time slot."
            );
        }

        // start must be before end
        if (!request.getStartDateTime().isBefore(request.getEndDateTime())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Start time must be before end time."
            );
        }

        // resource capacity (desk = 1, meeting room <= capacity)
        if (resource instanceof Desk && request.getAttendees() != 1) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "A desk can only accommodate 1 attendee."
            );
        }
        if (resource instanceof MeetingRoom && request.getAttendees() > resource.getCapacity()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Attendees exceed the room capacity of " + resource.getCapacity() + "."
            );
        }

        // if resource status == out of service
        if (resource.getStatus() == ResourceStatus.OUT_OF_SERVICE) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "This resource is out of service and cannot be booked."
            );
        }
    }

    private BigDecimal calculateCost(BookableResource resource, LocalDateTime startTime, LocalDateTime endTime) {
        long minutes = Duration.between(startTime, endTime).toMinutes();
        double cost = resource.getHourlyRate().doubleValue() * (minutes / 60.0);
        return BigDecimal.valueOf(cost).setScale(2, RoundingMode.HALF_UP);
    }
}