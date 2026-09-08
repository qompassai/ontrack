ONTrack – Privacy Policy
Last updated: September 7, 2026

This Privacy Policy explains how ONTrack (“the App”) handles information when you use it. By using the App, you agree to the practices described in this Policy.

If you do not agree with this Policy, please do not use the App.

1. Information We Collect
1.1 Information You Provide
The App collects information that you voluntarily enter, such as:

Job addresses, stop lists, and route configuration you add to plan a route.

Feedback you send us by email or other support channels.

All of this data is stored locally on your device inside the App's own storage. ONTrack has no account system and no backend server of its own — there is nothing to sync it to.

1.2 Automatically Collected Information
The App does not use analytics or crash-reporting SDKs. If a future release adds any, this Policy will be updated first and the change will be reflected in the Play Store Data Safety section before it ships.

1.3 Location Data
If you grant the Location permission, the App reads your device's last known GPS/network location (via Android's LocationManager) to center the map on your current position and to optionally use it as a route start point. This location is used on-device only and is not transmitted to us — it is never sent to any ONTrack server, because none exists. It may be sent to a routing/geocoding provider as described in Section 3 below if you use those features with your current location as a stop.

1.4 Voice Input
If you grant the Microphone permission, the App can transcribe spoken stop entries to text using an on-device Whisper (whisper.cpp) model that you download once during setup. Audio is processed entirely on your device and is never uploaded anywhere.

2. How We Use Information
We use the information described above to:

Provide and operate the App's route-planning and optimization features.

Geocode the addresses you enter into map coordinates, and compute drive-time/distance between your stops, using the third-party services listed in Section 3.

Respond to user requests, questions, or support inquiries.

We do not sell your personal data, and we have no analytics pipeline of our own to sell it from.

3. Third‑Party Services
ONTrack has no backend server. To turn the addresses you type into map coordinates and routes, the App sends the address text or coordinates you enter directly from your device to one of the following, depending on which backend you select in Settings:

OpenStreetMap Nominatim (nominatim.openstreetmap.org) — default geocoding backend. Receives the address text you enter. See the [OSMF Privacy Policy](https://osmfoundation.org/wiki/Privacy_Policy).

Project OSRM public demo server (router.project-osrm.org) — default routing backend. Receives the coordinates of your stops to compute a distance/time matrix.

ip-api.com — used only as a coarse fallback to estimate your approximate location from your network connection when device GPS is unavailable. Receives your device's public IP address.

Google Maps Platform (Geocoding API and Distance Matrix API) — optional, only used if you supply your own Google Maps API key in Settings and select Google as the backend. Receives the address text and/or coordinates of your stops. See [Google's Privacy Policy](https://policies.google.com/privacy).

Google Play — used by Android itself for App distribution and updates, independent of the App's own code.

We do not control these third parties' own data retention or use of the data once it is sent to them; please refer to their privacy policies linked above. You can avoid all of them by entering coordinates directly instead of addresses, though drive-time optimization requires at least one routing backend.

4. Data Storage and Retention
Job addresses, stop lists, and settings are stored locally on your device only, inside the App's private storage, until you delete them or uninstall the App. We do not operate any server that stores this data. We retain nothing on our end beyond email correspondence you initiate with us.

5. Data Sharing and Disclosure
We may share information in the following limited situations:

Geocoding/routing providers: With the OpenStreetMap Nominatim, OSRM, ip-api.com, or Google Maps services described in Section 3, only the address text or coordinates needed to fulfill your request.

Legal requirements: When required to comply with applicable law, legal processes, or valid governmental requests.

Protection of rights: When necessary to protect our rights, property, safety, or that of users or the public.

We do not share your personal data with third parties for their own marketing purposes, and we do not sell it.

6. Your Choices and Controls
You can:

Control the Location and Microphone permissions via your device's App settings at any time; the App degrades gracefully without them (you can type addresses and stop entries manually).

Choose which geocoding/routing backend to use (or enter coordinates directly to avoid sending address text to any third party) in the App's Settings.

Delete local app data by clearing the app’s storage or uninstalling the App from your device — this removes all locally stored addresses, routes, and settings.

If you contact us directly, you may request deletion or clarification of information you have provided, where technically feasible and not otherwise required to be retained by law.

7. Children’s Privacy
The App is not intended for children under 13 (or a higher age where required by local law), and we do not knowingly collect personal data from children in that age group. If we learn that we have inadvertently collected data from a child, we will take reasonable steps to delete it.

8. Security
We take reasonable technical and organizational measures to protect information processed by the App against unauthorized access, loss, or misuse. However, no method of transmission or storage is completely secure, and we cannot guarantee absolute security.

9. Changes to This Policy
We may update this Privacy Policy from time to time. When we do, we will revise the “Last updated” date at the top of this page. Your continued use of the App after any changes means you accept the updated Policy.

10. Contact Us
If you have questions about this Privacy Policy or about how ONTrack handles data, you can contact us at:

Email: matt@aflabs.io

Please include “ONTrack Privacy” in the subject line so we can process your request more efficiently.
