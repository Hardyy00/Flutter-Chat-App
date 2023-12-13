import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatefulWidget {
  const ChatMessages({super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  final authenticatedUser = FirebaseAuth.instance.currentUser!.uid;

  void pushNotifications() async {
    final fpm = FirebaseMessaging.instance;

    await fpm.requestPermission();

    await fpm.subscribeToTopic('income-message');
  }

  @override
  void initState() {
    super.initState();
    pushNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('sentAt', descending: true)
          .snapshots(),
      builder: (context, chatsSnapshot) {
        if (chatsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!chatsSnapshot.hasData || chatsSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No Messages to display"),
          );
        }

        if (chatsSnapshot.hasError) {
          return const Center(
            child: Text("Uh Oh! Something went wrong"),
          );
        }

        final chatMessages = chatsSnapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          itemCount: chatMessages.length,
          itemBuilder: (context, index) {
            final currentUserData = chatMessages[index].data();
            final nextUserData = index + 1 < chatMessages.length
                ? chatMessages[index + 1].data()
                : null;

            final currentUserId = currentUserData['userID'];
            final nextUserId =
                nextUserData != null ? nextUserData['userID'] : null;
            final isSameUserMessage = currentUserId == nextUserId;

            if (isSameUserMessage) {
              return MessageBubble.next(
                  message: currentUserData['message'],
                  isMe: currentUserId == authenticatedUser);
            } else {
              return MessageBubble.first(
                  userImage: currentUserData['userImage'],
                  username: currentUserData['userName'],
                  message: currentUserData['message'],
                  isMe: authenticatedUser == currentUserId);
            }
          },
        );
      },
    );
  }
}
