
package qa.udst.coworkhub.repository;

import qa.udst.coworkhub.entity.Booking;
import qa.udst.coworkhub.entity.BookingStatus;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Long> {

    // Find bookings belonging to a specific member
    List<Booking> findByMemberId(Long memberId);

    // Find bookings for a specific resource
    List<Booking> findByResourceId(Long resourceId);

    // Find bookings by status
    List<Booking> findByStatus(BookingStatus status);

    // Check for overlapping confirmed bookings
    @Query("""
        SELECT COUNT(b) > 0
        FROM Booking b
        WHERE b.resource.id = :resourceId
        AND b.status = :status
        AND b.startDateTime < :endDateTime
        AND b.endDateTime > :startDateTime
        """)
    boolean hasOverlappingBooking(
            @Param("resourceId") Long resourceId,
            @Param("status") BookingStatus status,
            @Param("startDateTime") LocalDateTime startDateTime,
            @Param("endDateTime") LocalDateTime endDateTime
    );

    // Check for overlapping bookings when updating an existing booking
    @Query("""
        SELECT COUNT(b) > 0
        FROM Booking b
        WHERE b.resource.id = :resourceId
        AND b.status = :status
        AND b.id <> :bookingId
        AND b.startDateTime < :endDateTime
        AND b.endDateTime > :startDateTime
        """)
    boolean hasOverlappingBookingExcludingCurrent(
            @Param("resourceId") Long resourceId,
            @Param("status") BookingStatus status,
            @Param("startDateTime") LocalDateTime startDateTime,
            @Param("endDateTime") LocalDateTime endDateTime,
            @Param("bookingId") Long bookingId
    );
}
