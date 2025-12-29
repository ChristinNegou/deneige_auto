const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
let firebaseApp = null;

const initializeFirebase = () => {
    if (firebaseApp) {
        return firebaseApp;
    }

    try {
        // Check if we have the service account credentials
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
            firebaseApp = admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
            console.log('Firebase Admin SDK initialized with service account');
        } else if (process.env.FIREBASE_PROJECT_ID) {
            // Use application default credentials or environment variables
            firebaseApp = admin.initializeApp({
                projectId: process.env.FIREBASE_PROJECT_ID,
            });
            console.log('Firebase Admin SDK initialized with project ID');
        } else {
            console.warn('Firebase credentials not configured. Push notifications disabled.');
            return null;
        }
    } catch (error) {
        console.error('Error initializing Firebase:', error.message);
        return null;
    }

    return firebaseApp;
};

/**
 * Send a push notification to a single device
 * @param {string} fcmToken - The device's FCM token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Additional data payload
 * @returns {Promise<object>} - Firebase response
 */
const sendPushNotification = async (fcmToken, title, body, data = {}) => {
    if (!firebaseApp) {
        console.warn('Firebase not initialized. Skipping push notification.');
        return null;
    }

    if (!fcmToken) {
        console.warn('No FCM token provided. Skipping push notification.');
        return null;
    }

    try {
        const message = {
            token: fcmToken,
            notification: {
                title,
                body,
            },
            data: {
                ...Object.fromEntries(
                    Object.entries(data).map(([k, v]) => [k, String(v)])
                ),
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'deneige_notifications',
                    priority: 'high',
                    defaultSound: true,
                    defaultVibrateTimings: true,
                },
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title,
                            body,
                        },
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };

        const response = await admin.messaging().send(message);
        console.log('Push notification sent successfully:', response);
        return { success: true, messageId: response };
    } catch (error) {
        console.error('Error sending push notification:', error.message);

        // Handle invalid token
        if (error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered') {
            return { success: false, invalidToken: true, error: error.message };
        }

        return { success: false, error: error.message };
    }
};

/**
 * Send push notifications to multiple devices
 * @param {string[]} fcmTokens - Array of FCM tokens
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Additional data payload
 * @returns {Promise<object>} - Firebase response with success/failure counts
 */
const sendMulticastNotification = async (fcmTokens, title, body, data = {}) => {
    if (!firebaseApp) {
        console.warn('Firebase not initialized. Skipping multicast notification.');
        return null;
    }

    if (!fcmTokens || fcmTokens.length === 0) {
        console.warn('No FCM tokens provided. Skipping multicast notification.');
        return null;
    }

    // Filter out null/undefined tokens
    const validTokens = fcmTokens.filter(token => token);
    if (validTokens.length === 0) {
        return null;
    }

    try {
        const message = {
            tokens: validTokens,
            notification: {
                title,
                body,
            },
            data: {
                ...Object.fromEntries(
                    Object.entries(data).map(([k, v]) => [k, String(v)])
                ),
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'deneige_notifications',
                    priority: 'high',
                    defaultSound: true,
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                    },
                },
            },
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Multicast sent: ${response.successCount} success, ${response.failureCount} failures`);

        // Collect invalid tokens for cleanup
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
            if (!resp.success) {
                const error = resp.error;
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    invalidTokens.push(validTokens[idx]);
                }
            }
        });

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
            invalidTokens,
        };
    } catch (error) {
        console.error('Error sending multicast notification:', error.message);
        return { success: false, error: error.message };
    }
};

/**
 * Send a notification by topic (all subscribed devices)
 * @param {string} topic - The topic name
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Additional data payload
 */
const sendTopicNotification = async (topic, title, body, data = {}) => {
    if (!firebaseApp) {
        console.warn('Firebase not initialized. Skipping topic notification.');
        return null;
    }

    try {
        const message = {
            topic,
            notification: {
                title,
                body,
            },
            data: {
                ...Object.fromEntries(
                    Object.entries(data).map(([k, v]) => [k, String(v)])
                ),
            },
            android: {
                priority: 'high',
            },
        };

        const response = await admin.messaging().send(message);
        console.log('Topic notification sent:', response);
        return { success: true, messageId: response };
    } catch (error) {
        console.error('Error sending topic notification:', error.message);
        return { success: false, error: error.message };
    }
};

module.exports = {
    initializeFirebase,
    sendPushNotification,
    sendMulticastNotification,
    sendTopicNotification,
};
