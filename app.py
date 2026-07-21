import streamlit as st
import pandas as pd
import psycopg2
import os
import matplotlib.pyplot as plt
from datetime import datetime

# Set page configuration
st.set_page_config(page_title="GCP Cloud Guestbook", page_icon="📝", layout="wide")

# Page headers
st.title("📝 GCP Cloud Guestbook & Message Board")
st.markdown("A simple message board to record visitor comments and visualize sentiments in real-time.")

# Database connection credentials from environment
def get_db_connection():
    conn = psycopg2.connect(
        host=os.environ.get("DB_HOST", "localhost"),
        database=os.environ.get("DB_NAME", "postgres"),
        user=os.environ.get("DB_USER", "postgres"),
        password=os.environ.get("DB_PASSWORD", "password"),
        port=os.environ.get("DB_PORT", "5432")
    )
    # Enable autocommit to avoid transaction locking deadlocks
    conn.autocommit = True
    return conn

# Initialize table on startup
def init_db():
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS guestbook (
                id SERIAL PRIMARY KEY,
                visitor_name VARCHAR(100) NOT NULL,
                message TEXT NOT NULL,
                sentiment VARCHAR(30) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        cur.close()
    except Exception as e:
        st.error(f"Failed to connect to database: {e}")
    finally:
        if conn:
            conn.close()

# Run database initialization
init_db()

# Helper function to load data
def load_messages():
    conn = get_db_connection()
    try:
        df = pd.read_sql(
            "SELECT visitor_name AS \"Visitor\", message AS \"Message\", sentiment AS \"Sentiment\", created_at AS \"Posted At\" FROM guestbook ORDER BY created_at DESC",
            conn
        )
        return df
    finally:
        conn.close()

# Helper function to save a message
def save_message(name, message, sentiment):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO guestbook (visitor_name, message, sentiment) VALUES (%s, %s, %s)",
            (name, message, sentiment)
        )
        cur.close()
    finally:
        conn.close()

# Create two columns layout
col1, col2 = st.columns([1, 2])

# Left Column: Sign the Guestbook
with col1:
    st.header("Sign the Guestbook")
    
    with st.form("guestbook_form", clear_on_submit=True):
        visitor_name = st.text_input("Your Name", max_chars=50, placeholder="John Doe")
        visitor_message = st.text_area("Your Message", max_chars=300, placeholder="Write something nice...")
        visitor_sentiment = st.selectbox(
            "How do you feel about this Cloud Demo?",
            ["Impressed", "Happy", "Curious", "Neutral", "Excited"]
        )
        
        submit_btn = st.form_submit_button("Submit Message")
        
        if submit_btn:
            if not visitor_name.strip() or not visitor_message.strip():
                st.warning("Please fill out both your Name and Message.")
            else:
                try:
                    save_message(visitor_name, visitor_message, visitor_sentiment)
                    st.success("Thank you for signing the guestbook!")
                    st.rerun()  # Refresh screen to show the new message
                except Exception as e:
                    st.error(f"Error saving message: {e}")

# Right Column: Dashboard & Entries Log
with col2:
    st.header("Guestbook Entries & Analytics")
    try:
        df = load_messages()
        
        if df.empty:
            st.info("No messages have been left yet. Be the first to write a message on the left!")
        else:
            # 1. Analytics & Metrics
            total_messages = len(df)
            unique_visitors = df["Visitor"].nunique()
            
            m_col1, m_col2 = st.columns(2)
            m_col1.metric("Total Messages", total_messages)
            m_col2.metric("Unique Visitors", unique_visitors)
            
            # 2. Charts Section
            st.subheader("Visitor Sentiments")
            sentiment_counts = df["Sentiment"].value_counts()
            
            fig, ax = plt.subplots(figsize=(5, 3))
            fig.patch.set_facecolor('#0e1117')
            ax.set_facecolor('#0e1117')
            
            # Draw Pie Chart
            wedges, texts, autotexts = ax.pie(
                sentiment_counts,
                labels=sentiment_counts.index,
                autopct='%1.1f%%',
                startangle=140,
                textprops=dict(color="w")
            )
            plt.setp(autotexts, size=8, weight="bold")
            st.pyplot(fig)
            
            # 3. Log Table
            st.subheader("Messages Log")
            st.dataframe(df, use_container_width=True, hide_index=True)
            
    except Exception as e:
        st.warning("Database connection is not configured or offline. Set your DB_HOST environment variables to connect.")
