# Lost@KUET  
A Lost and Found App for KUET Campus  

---

## Overview
**Lost@KUET** is an Android mobile application developed using **Flutter** and powered by **Supabase** for backend and authentication.  
The app provides a secure, verified, and interactive platform for students of **Khulna University of Engineering & Technology (KUET)** to manage lost and found items within the campus.  

Users can post lost or found items, search posts, communicate directly through in-app chat, and receive real-time notifications when new items are uploaded.  
The project was developed as part of the **Information System Design Lab**, integrating tools such as **Jira**, **GitHub**, and multiple system design methodologies.

---

## Objectives
- To create a digital platform for managing lost and found items efficiently within KUET.  
- To ensure secure and verified access using KUET email authentication via Supabase.  
- To implement real-time posting, searching, and communication features.  
- To apply information system design principles and software project management tools such as Jira and GitHub.  

---

## Core Features

### 1. User Authentication & Authorization
- Login / Signup system  
- Sign up and sign in with **Google**  
- **Forgot password** feature  
- **Sign out** functionality  
- Secure authentication and authorization using **Supabase Auth**  

---

### 2. Lost/Found Items Management
- Users can post both **lost** and **found** items  
- Receive **real-time notifications** when a new post is uploaded  
- Each post contains:
  - Title  
  - Description  
  - Location (with real-time map integration)  
  - Category  
  - Status (Lost / Found)  
  - Images  
  - Timestamp  
- Users can view detailed information by tapping on any post  

---

### 3. Search Functionality
- Search through all posts  
- Filter posts using **keywords**, **category**, or **location**  
- Search by title for quick access  

---

### 4. Communication
- Direct in-app **chat** between users  
- Option to **share images** within messages  
- “Contact Poster” feature redirects users to the chat window of the post owner  

---

### 5. Profile Management
- Users can update profile details or delete their account  
- **Student verification** via KUET email  
- **Posts tab** shows the user’s uploaded posts  
- **Claims tab** displays user’s claimed lost items  
- When an item is marked as *found*, it is automatically removed from the claims tab  

---

## Tech Stack

| Category | Technology |
|-----------|-------------|
| Framework | Flutter (Dart) |
| Backend & Database | Supabase |
| Authentication | Supabase Auth with Google Sign-In |
| Notifications | Supabase Realtime |
| Map Integration | Google Maps API |
| Version Control | Git & GitHub |
| Project Management | Jira |
| UI Design | Figma |
| IDE | Android Studio / VS Code |

---

## System Design Tools
- **Use Case Diagram** – defines interactions between users and system functionalities  
- **Activity Diagram** – represents workflow of processes like posting and claiming items  
- **Data Flow Diagram (DFD)** – shows data movement between components  
- **Class Diagram** – visualizes relationships between system entities (User, Post, Message, Claim)  
- **Sequence Diagram** – details message flow between frontend and backend  
- **Gantt Chart** – outlines project schedule and task distribution  

---

## Installation & Setup Guide

### Prerequisites
- Install [Flutter SDK](https://flutter.dev/docs/get-started/install)  
- Install [Android Studio](https://developer.android.com/studio)
- Get dependencies
- Create a project on [Supabase](https://supabase.io)  
- Obtain Supabase project URL and API key  
- Enable Authentication and Storage in Supabase  
- Set up Google Maps API key  

### Steps
1. **Clone the repository**
   ```bash
   git clone https://github.com/ShormiGhosh/lostatkuet.git

2. **Navigate into the project**
   cd lostatkuet
   
4. **Install dependencies**
   flutter pub get

5. **Configure environment variables**

   Add your Supabase credentials (supabaseUrl, supabaseKey) in the project configuration file

6. **Add Google Maps API key**

   Insert your API key into the AndroidManifest.xml file

7. **Run the application**

   flutter run
   

---


### Project Management

- Managed using Jira for sprint tracking, task management, and progress visualization

- Version control and collaboration handled through GitHub

- User interface mockups designed using Figma prior to implementation
  

---


### Future Enhancements

- Push notifications for newly added posts near a user’s location

- AI-based image classification to auto-detect item categories

- Admin dashboard for content verification and moderation

- Offline caching for viewing posts without internet access


--- 


### Learning Outcomes

- Practical understanding of information system design and modeling

- Hands-on experience integrating Flutter with Supabase

- Improved team collaboration using agile tools such as Jira and GitHub

- Better understanding of UI/UX principles in mobile application design
  

---


### License

- This project is developed for academic purposes under the
  Information System Design Lab,
  Department of Computer Science and Engineering, KUET.
  © 2025 Lost@KUET Team. All rights reserved.

---


### Contact

For queries or collaboration:
📧 Email: lostatkuet@gmail.com
