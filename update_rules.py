import re

path = 'firestore.rules'
try:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Modify to add streak and lastLoginDate if not already there
    if 'streak' not in content:
        content = re.sub(r"'photoUrl'\s*\]\)", "'photoUrl',\n        'streak',\n        'lastLoginDate'\n      ])", content)

    # Modify daily_logs to allow create/update
    if 'allow create, update, delete: if false;' in content:
        content = content.replace('allow create, update, delete: if false;', 'allow create, update: if isOwner(userId);\n        allow delete: if false;')

    # Add workout_sessions
    w_session = '\n\n      match /workout_sessions/{sessionId} {\n        allow read, write: if isOwner(userId);\n      }'
    if 'workout_sessions' not in content:
        # insert after daily_logs block terminates 
        content = re.sub(r'(match /daily_logs/\{logId\} \{.*?allow delete: if false;\s*\})', r'\1' + w_session, content, flags=re.DOTALL)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('SUCCESS')
except Exception as e:
    print('FAIL:', e)
