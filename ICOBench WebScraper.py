
# coding: utf-8

# # ICOBench WebScraper

# In[777]:


#import necessary packages
from urllib.request import urlopen, Request
from bs4 import BeautifulSoup
import time
import pandas as pd
import numpy as np


# In[778]:


#set header
headers = {
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36'}


# In[779]:


#base url set to ended ICO's
url = 'https://icobench.com/icos?filterBonus=&filterBounty=&filterMvp=&filterKyc=&filterExpert=&filterFar=&filterHot=&filterFreeTokens=&filterTokenClass=&filterSort=&filterCategory=all&filterRating=any&filterStatus=ended&filterPublished=&filterCountry=any&filterRegistration=0&filterExcludeArea=none&filterPlatform=any&filterCurrency=any&filterTrading=any&s=&filterStartAfter=&filterEndBefore='


# In[784]:


#create list to store info on all icos
all_icos = []
all_creators=dict()
all_experts=dict()

#go through each page
for i in range(360):
    #load web page
    url = 'https://icobench.com/icos?page='+str(i+1)+'&filterBonus=&filterBounty=&filterMvp=&filterKyc=&filterExpert=&filterFar=&filterHot=&filterFreeTokens=&filterTokenClass=&filterSort=&filterCategory=all&filterRating=any&filterStatus=ended&filterPublished=&filterCountry=any&filterRegistration=0&filterExcludeArea=none&filterPlatform=any&filterCurrency=any&filterTrading=any&s=&filterStartAfter=&filterEndBefore='
    req = Request(url=url, headers=headers)
    client = urlopen(req)
    page=client.read()
    client.close()
    soup = BeautifulSoup(page,'html.parser')
    
    #get list of ICO's
    ico_list = soup.findAll('div',{'class':'ico_list'})[0]
    table = ico_list.find_all('tr')
    
    #go through each coin per page
    for j in range(1,len(table)):
        #get url for each token
        ico = table[j]
        url = 'https://icobench.com'+ico.findAll('a')[0]['href']
        
        try:
            #jump to token url
            req = Request(url=url, headers=headers)
            client = urlopen(req)
            page = client.read()
            client.close()
            soup = BeautifulSoup(page,'html.parser')
        except:
            continue
        
        #create diciotnary for ico data
        ico_data = dict()
        
        #get header information
        ico_data['Name'] = soup.h1.text
        if ico_data['Name']=='404':
            continue
        ico_data['Tagline'] = soup.h2.text
        
        #get description
        ico_data['Description']= soup.findAll('div',{'class':'ico_information'})[0].p.text
        
        #get list of tags
        tags=[]
        for tag in soup.findAll('div',{'class':'categories'})[0]:
            tags.append(tag['title'])         
        ico_data['Tags']=tags
        
        #get rating information
        ico_data['Rating']=float(soup.findAll('div',{'itemprop':'ratingValue'})[0].a.findAll('div')[0].text)
        ico_data['ExpertRatings']= int(soup.findAll('div',{'itemprop':'ratingValue'})[0].small.text.split()[0])
        ico_data['BenchyProfieRating']=float(soup.findAll('div',{'class':'distribution'})[0].findAll('div',
                                        {'class':'col_4'})[0].findAll('div',{'class':'wrapper'})[0].text.split()[1])
        
        teamrating=soup.findAll('div',{'class':'distribution'})[0].findAll('div',
                                        {'class':'col_75'})[0].findAll('div',{'class':'col_4 col_3'})[0].text.split()[0]
        if teamrating!='-':
            ico_data['TeamRating']=float(teamrating)
        
        visionrating=soup.findAll('div',{'class':'distribution'})[0].findAll('div',
                                        {'class':'col_75'})[0].findAll('div',{'class':'col_4 col_3'})[1].text.split()[0]
        if visionrating!='-':
            ico_data['VisionRating']=float(visionrating)
        
        
        productrating=soup.findAll('div',{'class':'distribution'})[0].findAll('div',
                                        {'class':'col_75'})[0].findAll('div',{'class':'col_4 col_3'})[2].text.split()[0]
        if productrating!='-':
            ico_data['ProductRating']=float(productrating)
        
        #get status information
        data_rows = soup.findAll('div',{'class':'data_row'})
        for row in soup.findAll('div',{'class':'data_row'}):
            label=row.findAll('div',{'class':'col_2'})[0].text.strip()
            value=row.findAll('div',{'class':'col_2'})[1].text.strip()
            ico_data[label]=value
        
        #get social media links
        socials = soup.findAll('div',{'class':'socials'})
        if len(socials)>0:
            for social in socials[0].findAll('a'):
                ico_data[social.text]=social['href']
            
        #get about info
        about=ico_data['About']=soup.findAll('div',{'id':'about'})[0].p
        if about!=None:
            ico_data['About']=soup.findAll('div',{'id':'about'})[0].p.text
        else:
            ico_data['About']=soup.findAll('div',{'id':'about'})[0].text
            
        #get milestones
        milestone_list=[]
        milestones = soup.findAll('div',{'id':'milestones'})[0].findAll('div',{'class':'box'})[0].findAll('div',{'class':'row'})
        for milestone in milestones:
            milestone_dict=dict()
            milestone_dict['Date']=milestone.findAll('div',{'class':'condition'})[0].text
            milestone_dict['Text']=milestone.p.text.strip()
            milestone_list.append(milestone_dict)
        ico_data['Milestones']=milestone_list
        
        #get financial info
        for row in soup.findAll('div',{'id':'financial'})[0].findAll('div',{'class':'row'}):
            try:
                label = row.findAll('div',{'class':'label'})[0].text
                if label=='Type':
                    label='TokenType'
                value = row.findAll('div',{'class':'value'})[0].text
            except:
                if row.h4.text=='Bonus':
                    label= row.h4.text
                    value = row.findAll('div',{'class':'bonus_text'})[0].text.strip().split('\n')
                    value[:] = [x for x in value if x]
            ico_data[label]=value
            
        #get team member info
        group_num=0
        for group in soup.findAll('div',{'id':'team'})[0].findAll('div',{'class':'row'}):
            group_num+=1
            group_members=dict()
            for member in group.findAll('div',{'class':'col_3'}):
                member_name = member.a['title']
                member_url = member.a['href']
                all_creators[member_url]=member_name
                group_members[member_url]=member_name
            ico_data['Team'+str(group_num)] = group_members
            
        #get KYC Report info
        ico_data['KYCResult']=soup.findAll('div',{'class':'kyc_result'})[0].find('div')['class'][1]
        
        kyc_members = dict()
        members = soup.findAll('div',{'class':'kyc_report'})
        if len(members)!=0:
            for member in members[0].findAll('div',{'class':'row'}):
                label=' '.join(member.text.split()[:-1])
                result = memebr.text.split()[-1]
                kyc_members[label]=result
        ico_data['KYCMembers']=kyc_members
        
        #get individual rating info
        reviews = list()
        for review in soup.findAll('div',{'class':'ratings_list'})[0].findAll('div',{'class':'row'}):
            review_dict = dict()

            #don't include benchy
            try:
                rating_id=review.a['id'][2:]
            except:
                continue

            #data
            expert_url = review.findAll('div',{'class':'data'})[0].a['href']
            expert_name=review.findAll('div',{'class':'data'})[0].a.text
            all_experts[expert_url]=expert_name
            review_dict['ExpertURL']=expert_url
            review_dict['ExpertName']=expert_name

            #title
            review_dict['Info']=review.findAll('div',{'class':'title'})[0].text

            #text
            text=review.findAll('div',{'data-id':rating_id})
            if len(text)!=0:
                review_dict['Text']=text[0].p.text

            #ratings from each review
            for rating in review.findAll('div',{'class':'rate'})[0].findAll('div',{'class':'col_3'}):
                review_dict[rating.text[1:]]= rating.text[0]

            #get weight
            review_dict['Weight']=int(review.findAll('div',{'class':'distribution'})[0].text.strip().split('%')[0])
        
            #getting rating upvotes/downvotes
            if len(text)!=0:
                agree=review.findAll('div',{'data-id':rating_id})[0].findAll('div',{'class':'agree'})[0].text
                if(agree=='Agree'):
                    review_dict['Agree']=0
                else:
                    review_dict['Agree']=agree[1:-5]

                disagree=review.findAll('div',{'data-id':rating_id})[0].findAll('div',{'class':'agree dis'})[0].text
                if disagree=='Disagree':
                    review_dict['Disagree']=0
                else:
                    review_dict['Disagree']=disagree[1:-8]

            reviews.append(review_dict)
            
        ico_data['Reviews']=reviews
        
        #get whitepaper
        ico_data['Whitepaper']=soup.findAll('div',{'name':'whitepaper'})[0].p.object.get('data')
        
        #append data to list
        all_icos.append(ico_data)
        
        time.sleep(10)
    
    print(str(round((i+1)*100/360,2))+'% complete')
print('done')


# In[773]:


socials = soup.findAll('div',{'class':'socials'})
socials


# In[774]:


i


# In[783]:


len(ico_data)


# In[785]:


df_experts = pd.DataFrame(all_experts.values(),index=all_experts.keys())
df_experts.columns=['Name']
df_experts.head()


# In[786]:


df_experts.info()


# In[787]:


df_creators = pd.DataFrame(all_creators.values(),index=all_creators.keys())
df_creators.columns=['Name']
df_creators.head()


# In[788]:


df_creators.info()


# In[789]:


df = pd.DataFrame(all_icos)
df.head()


# In[731]:


df.iloc[8]['Milestones']


# In[790]:


df.info()

