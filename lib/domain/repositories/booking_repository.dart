import 'package:parkflow/domain/entities/booking.dart';

abstract class BookingRepository {
  /// Reservas donde el usuario es anfitrión (para ganancias HU-13).
  Future<List<Booking>> getHostBookings(String hostId);

  /// Driver: reservas activas del conductor (HU-08).
  Future<List<Booking>> getDriverBookings(String driverId);

  /// Driver: extiende una reserva solicitando más horas (HU-08).
  Future<String> extendBooking(String bookingId, double extraHours);
}
