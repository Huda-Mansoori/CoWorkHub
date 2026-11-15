package qa.udst.coworkhub.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.web.server.ResponseStatusException;

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

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public Booking createBooking(BookingRequest request) {
        if (request.getMemberId() == null || request.getResourceId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Member and resource are required.");
        }


        // 1. find member and resource by ID sent
        Member member = memberRepository.findById(request.getMemberId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Member not found with ID: " + request.getMemberId()
                ));

        BookableResource resource = resourceRepository.findForUpdate(request.getResourceId())
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

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public Booking updateBooking(Long bookingId, BookingRequest request) {
        Booking booking = bookingRepository.findForUpdate(bookingId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Booking not found with ID: " + bookingId
                ));

        // change status to cancelled
        if ("CANCELLED".equals(request.getStatus())) {
            booking.setStatus(BookingStatus.CANCELLED);
            return bookingRepository.save(booking);
        }

        if (booking.getStatus() == BookingStatus.CANCELLED) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Cannot update a cancelled booking."
            );
        }

        Long resourceId = request.getResourceId() != null
                ? request.getResourceId() : booking.getResource().getId();
        BookableResource resource = resourceRepository.findForUpdate(resourceId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND,
                            "Resource not found with ID: " + request.getResourceId()
                    ));

        // check business rules
        checkRules(resource, request, bookingId);

        // update fields
        booking.setResource(resource);
        booking.setStartDateTime(request.getStartDateTime());
        booking.setEndDateTime(request.getEndDateTime());
        booking.setAttendees(request.getAttendees());
        booking.setTotalCost(calculateCost(resource, request.getStartDateTime(), request.getEndDateTime()));

        return bookingRepository.save(booking);
    }

    public List<Booking> getBookingsByMember(Long memberId) {
        memberRepository.findById(memberId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Member not found with ID: " + memberId
                ));
        return bookingRepository.findByMemberId(memberId);
    }

    // ACTIVE status and no overlapping bookings
    public List<BookableResource> getAvailableResources(LocalDateTime start, LocalDateTime end) {
        if (!start.isBefore(end)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Start time must be before end time."
            );
        }
        List<BookableResource> availableResources = new ArrayList<>();
        for (BookableResource resource : resourceRepository.findByStatus(ResourceStatus.ACTIVE)) {
            boolean booked = bookingRepository.hasOverlappingBooking(
                    resource.getId(),
                    BookingStatus.CONFIRMED,
                    start,
                    end);
            if (!booked) {
                availableResources.add(resource);
            }
        }
        return availableResources;
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

        if (request.getAttendees() < 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Attendees must be at least 1.");
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