import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/util/date_util.dart';

class CampusEvent {
  final String id;
  final String name;
  final DateTime date;
  final String location;
  final double price;
  final String description;
  final String category;
  final String? imageUrl;
  final int colorValue;
  final int totalTickets;
  final int availableTickets;

  CampusEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.price,
    this.description = '',
    this.category = 'General',
    this.imageUrl,
    required this.colorValue,
    this.totalTickets = 100,
    this.availableTickets = 100,
  });

  factory CampusEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CampusEvent(
      id: doc.id,
      name: data['name'] ?? '',
      date: DateUtil.parse(data['date']),
      location: data['location'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      imageUrl: data['imageUrl'] ?? data['image'],
      colorValue: data['colorValue'] ?? 0xFF6366F1,
      totalTickets: data['totalTickets'] ?? 100,
      availableTickets: data['availableTickets'] ?? 100,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'location': location,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'colorValue': colorValue,
      'totalTickets': totalTickets,
      'availableTickets': availableTickets,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class EventTicket {
  final String id;
  final String eventId;
  final String userId;
  final String eventName;
  final DateTime eventDate;
  final String eventLocation;
  final int eventColorValue;
  final String ticketNumber;
  final DateTime purchaseDate;
  final String status;
  final String qrData;
  final String? eventImageUrl;

  EventTicket({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.eventName,
    required this.eventDate,
    required this.eventLocation,
    required this.eventColorValue,
    required this.ticketNumber,
    required this.purchaseDate,
    this.status = 'active',
    required this.qrData,
    this.eventImageUrl,
  });

  factory EventTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventTicket(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      eventName: data['eventName'] ?? '',
      eventDate: DateUtil.parse(data['eventDate']),
      eventLocation: data['eventLocation'] ?? '',
      eventColorValue: data['eventColorValue'] ?? 0xFF6366F1,
      ticketNumber: data['ticketNumber'] ?? '',
      purchaseDate: DateUtil.parse(data['purchaseDate']),
      status: data['status'] ?? 'active',
      qrData: data['qrData'] ?? '',
      eventImageUrl: data['eventImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'eventName': eventName,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': eventLocation, // Note: kept as 'location' for historical sync if needed, but usually 'eventLocation'
      'eventLocation': eventLocation,
      'eventColorValue': eventColorValue,
      'ticketNumber': ticketNumber,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'status': status,
      'qrData': qrData,
      'eventImageUrl': eventImageUrl,
    };
  }
}
