-- Messaging Service Database Schema
-- This file initializes the database with the required tables for the messaging service

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    participant_from VARCHAR(255) NOT NULL,
    participant_to VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(participant_from, participant_to)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES conversations(id) ON DELETE CASCADE,
    from_address VARCHAR(255) NOT NULL,
    to_address VARCHAR(255) NOT NULL,
    message_type VARCHAR(10) NOT NULL CHECK (message_type IN ('sms', 'mms', 'email')),
    body TEXT NOT NULL,
    attachments JSONB DEFAULT '[]'::jsonb,
    messaging_provider_id VARCHAR(255),
    xillio_id VARCHAR(255),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('inbound', 'outbound'))
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON conversations(participant_from, participant_to);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);
CREATE INDEX IF NOT EXISTS idx_messages_direction ON messages(direction);

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at on conversations
CREATE TRIGGER update_conversations_updated_at 
    BEFORE UPDATE ON conversations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data for testing
INSERT INTO conversations (participant_from, participant_to) VALUES 
    ('+18045551234', '+12016661234'),
    ('user@usehatchapp.com', 'contact@gmail.com')
ON CONFLICT (participant_from, participant_to) DO NOTHING;

-- Insert sample messages
INSERT INTO messages (conversation_id, from_address, to_address, message_type, body, timestamp, direction) VALUES 
    (1, '+18045551234', '+12016661234', 'sms', 'Hello, this is a test SMS message', '2024-11-01T14:00:00Z', 'outbound'),
    (1, '+12016661234', '+18045551234', 'sms', 'Hi! Thanks for the message', '2024-11-01T14:05:00Z', 'inbound'),
    (2, 'user@usehatchapp.com', 'contact@gmail.com', 'email', 'This is a test email message', '2024-11-01T14:10:00Z', 'outbound')
ON CONFLICT DO NOTHING;
