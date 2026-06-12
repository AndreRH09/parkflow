import 'package:parkflow/domain/entities/booking.dart';

abstract class BookingRepository {
  /// Reservas donde el usuario es anfitrión (para ganancias HU-13).
  Future<List<Booking>> getHostBookings(String hostId);
}
